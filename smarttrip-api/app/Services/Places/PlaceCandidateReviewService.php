<?php

namespace App\Services\Places;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlacePhoto;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * F019 (US12) - approve = satu alur: promosikan candidate jadi places
 * (Place Details, Enterprise SKU), download foto ke storage lokal, lalu
 * satu call Gemini (translate + tag kategori + durasi + is_outdoor).
 * search_area candidate disalin jadi places.kecamatan gratis di sini.
 */
class PlaceCandidateReviewService
{
    public function __construct(
        private readonly GooglePlacesDetailsClient $detailsClient,
        private readonly GeminiEnrichmentClient $geminiClient,
    ) {}

    /**
     * Place Details gagal -> approve dibatalkan total, candidate tetap
     * pending (bisa dicoba lagi nanti). Foto/Gemini gagal SETELAH place
     * inti berhasil dibuat -> tidak membatalkan promosi (place tetap
     * berguna walau belum ada foto/tag) - dicatat ke log, admin bisa
     * lengkapi manual lewat CRUD places (F021).
     */
    public function approve(PlaceCandidate $candidate): Place
    {
        $details = $this->detailsClient->fetch($candidate->google_place_id);

        $place = DB::transaction(function () use ($candidate, $details) {
            $place = Place::create([
                'google_place_id' => $candidate->google_place_id,
                'name' => $details['name'] !== '' ? $details['name'] : $candidate->name,
                'type' => $candidate->type,
                'lat' => $details['lat'] ?: $candidate->lat,
                'lng' => $details['lng'] ?: $candidate->lng,
                'address' => $details['address'],
                'kecamatan' => $candidate->search_area,
                'rating' => $details['rating'],
                // Google tidak selalu balikin userRatingCount (tempat baru
                // tanpa review sama sekali) - places.review_count NOT NULL
                // dengan default 0, tapi Eloquent create() kirim NULL
                // eksplisit kalau tidak di-coalesce, menimpa default kolom.
                'review_count' => $details['review_count'] ?? 0,
                'opening_hours' => $details['opening_hours'],
                'description' => $details['description'],
                'phone' => $details['phone'],
                'website' => $details['website'],
                'business_status' => $details['business_status'],
                'types' => $details['types'],
                'price_level' => $details['price_level'],
                'source' => 'google',
                'category_tags_reviewed' => false,
            ]);

            $candidate->update(['status' => 'approved']);

            return $place;
        });

        $this->tryDownloadPhoto($place, $details['photo_reference']);
        $this->tryEnrichWithGemini($place);

        return $place->fresh();
    }

    public function reject(PlaceCandidate $candidate): void
    {
        $candidate->update(['status' => 'rejected']);
    }

    private function tryDownloadPhoto(Place $place, ?string $photoReference): void
    {
        if ($photoReference === null) {
            return;
        }

        try {
            $bytes = $this->detailsClient->downloadPhoto($photoReference);
            $path = 'places/'.$place->places_id.'/'.Str::random(16).'.jpg';
            Storage::disk('public')->put($path, $bytes);
            $url = Storage::disk('public')->url($path);

            $place->update(['photo_url' => $url]);
            PlacePhoto::create(['places_id' => $place->places_id, 'photo_url' => $url, 'sort_order' => 0]);
        } catch (RuntimeException $e) {
            Log::warning("Gagal download foto buat place {$place->places_id}: {$e->getMessage()}");
        }
    }

    private function tryEnrichWithGemini(Place $place): void
    {
        $availableSlugs = Category::query()->pluck('slug')->all();

        try {
            $enrichment = $this->geminiClient->enrich($place->name, $place->description, $availableSlugs);

            $place->update([
                'description_en' => $enrichment['description_en'],
                'estimated_visit_minutes' => $enrichment['estimated_visit_minutes'],
                'is_outdoor' => $enrichment['is_outdoor'],
            ]);

            if ($enrichment['category_tags'] !== []) {
                $categoryIds = Category::query()->whereIn('slug', $enrichment['category_tags'])->pluck('categories_id');
                $place->categories()->sync($categoryIds);
            }
        } catch (RuntimeException $e) {
            Log::warning("Gagal enrichment Gemini buat place {$place->places_id}: {$e->getMessage()}");
        }
    }
}
