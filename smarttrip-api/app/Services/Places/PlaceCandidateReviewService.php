<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Models\PlaceCandidate;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * F019 (US12) - approve = satu alur: promosikan candidate jadi places
 * (Place Details dari Geoapify sejak 2026-10-13), lalu satu call Gemini
 * (translate + tag kategori + durasi + is_outdoor). search_area candidate
 * disalin jadi places.kecamatan gratis di sini. Geoapify tidak punya foto,
 * jadi foto dilengkapi admin.
 */
class PlaceCandidateReviewService
{
    public function __construct(
        private readonly GeoapifyPlacesClient $detailsClient,
        private readonly PlaceEnrichmentService $enrichment,
        private readonly PlaceDuplicateFinder $duplicates,
    ) {}

    /**
     * Place Details gagal -> approve dibatalkan total, candidate tetap
     * pending (bisa dicoba lagi nanti). Gemini gagal SETELAH place
     * inti berhasil dibuat -> tidak membatalkan promosi (place tetap
     * berguna walau belum ada foto/tag) - dicatat ke log, admin bisa
     * lengkapi manual lewat CRUD places (F021). Kandidat yang ternyata
     * sudah ada di katalog (misal admin menambah tempatnya manual setelah
     * Discovery) ditolak sebelum memakai kredit Geoapify.
     *
     * Null when Google Maps lists the place as permanently closed: the
     * place is deleted from the catalog again and the candidate rejected,
     * so Discovery does not bring it back. An admin who knows better adds
     * it by hand.
     */
    public function approve(PlaceCandidate $candidate): ?Place
    {
        // A rejected candidate may still be approved (the admin changed their mind), an approved one is final.
        if ($candidate->status === 'approved') {
            throw new RuntimeException('kandidat ini sudah disetujui');
        }

        $existing = $this->duplicates->findPlace(
            $candidate->external_place_id, $candidate->name, (float) $candidate->lat, (float) $candidate->lng
        );
        if ($existing !== null) {
            throw new RuntimeException($existing->trashed()
                ? "pernah dihapus dari katalog sebagai \"{$existing->name}\""
                : "sudah ada di katalog sebagai \"{$existing->name}\"");
        }

        $details = $this->detailsClient->fetch($candidate->external_place_id);

        $place = DB::transaction(function () use ($candidate, $details) {
            $place = Place::create([
                'external_place_id' => $candidate->external_place_id,
                'name' => $details['name'] !== '' ? $details['name'] : $candidate->name,
                'type' => $candidate->type,
                'lat' => $details['lat'] ?: $candidate->lat,
                'lng' => $details['lng'] ?: $candidate->lng,
                'address' => $details['address'],
                'kecamatan' => $candidate->search_area,
                'opening_hours' => $details['opening_hours'],
                'description_id' => $details['description'],
                'types' => $details['types'],
                'source' => 'geoapify',
                'category_tags_reviewed' => false,
            ]);

            $candidate->update(['status' => 'approved']);

            return $place;
        });

        // The OSM tags from this fetch are the facts Gemini describes from.
        if ($this->tryEnrichWithGemini($place, $details['osm_tags'] ?? [])) {
            $place->delete();
            $candidate->update(['status' => 'rejected']);

            return null;
        }

        return $place->fresh();
    }

    public function reject(PlaceCandidate $candidate): void
    {
        // Rejecting an approved candidate would leave its place in the catalog under a rejected status.
        if ($candidate->status !== 'pending') {
            throw new RuntimeException('hanya kandidat yang menunggu review yang bisa ditolak');
        }

        $candidate->update(['status' => 'rejected']);
    }

    /**
     * Rejects pending candidates that duplicate a catalog place or an earlier
     * candidate, for candidates inserted before name + distance dedup existed
     * or before a matching place was added by hand.
     *
     * @return int number of candidates rejected
     */
    public function rejectPendingDuplicates(): int
    {
        $rejected = 0;

        PlaceCandidate::where('status', 'pending')
            ->orderBy('place_candidates_id')
            ->each(function (PlaceCandidate $candidate) use (&$rejected) {
                [$externalPlaceId, $name, $lat, $lng] = [
                    $candidate->external_place_id, $candidate->name, (float) $candidate->lat, (float) $candidate->lng,
                ];

                if ($this->duplicates->findPlace($externalPlaceId, $name, $lat, $lng) === null
                    && $this->duplicates->findCandidate($externalPlaceId, $name, $lat, $lng, $candidate->place_candidates_id) === null) {
                    return;
                }

                $this->reject($candidate);
                $rejected++;
            });

        return $rejected;
    }

    /**
     * True when Google Maps lists the place as permanently closed.
     */
    private function tryEnrichWithGemini(Place $place, array $osmTags): bool
    {
        try {
            $plan = $this->enrichment->plan($place, $osmTags);
            if ($plan['closed_permanently']) {
                return true;
            }
            $this->enrichment->apply($place, $plan);
        } catch (RuntimeException $exception) {
            Log::warning("Gagal enrichment Gemini buat place {$place->places_id}: {$exception->getMessage()}");
        }

        return false;
    }
}
