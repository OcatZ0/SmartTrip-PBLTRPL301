<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Services\Itinerary\HotelRecommender;
use App\Services\Itinerary\ItineraryGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\ProhibitedIf;
use Illuminate\Validation\ValidationException;
use RuntimeException;

/**
 * Trip setup + F008 (docs/prd design spec Section 7 & 12).
 */
class TripController extends Controller
{
    /**
     * F011: daftar trip yang pernah dibuat user login - punya sendiri saja
     * (bukan yang dibagikan ke dia - itu GET /api/trips/shared, F016).
     * Terurut trip terbaru dulu.
     */
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $trips = $request->user()->trips()
            ->withCount('days')
            ->orderByDesc('created_at')
            ->paginate($perPage);

        return response()->json($trips);
    }

    /**
     * F016: tab "Dibagikan ke Saya" - trip yang di-share ke user login
     * sebagai viewer (baris trip_viewers), bukan trip miliknya sendiri.
     * Terurut kapan diundang (added_at) terbaru dulu.
     */
    public function shared(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $trips = $request->user()->sharedTrips()
            ->withCount('days')
            ->orderByDesc('trip_viewers.added_at')
            ->paginate($perPage);

        return response()->json($trips);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'title' => ['nullable', 'string', 'max:255'],
            'num_days' => ['required', 'integer', 'min:1'],
            'budget_total' => ['required', 'integer', 'min:1'],
            'start_date' => ['required', 'date'],
            'daily_start_time' => ['nullable', 'date_format:H:i'],
            'daily_end_time' => ['nullable', 'date_format:H:i', 'after:daily_start_time'],
            'has_own_hotel' => ['sometimes', 'boolean'],
        ]);

        $trip = $request->user()->trips()->create([
            'title' => $data['title'] ?? 'Trip Batam',
            'num_days' => $data['num_days'],
            'budget_total' => $data['budget_total'],
            'start_date' => $data['start_date'],
            'has_own_hotel' => $data['has_own_hotel'] ?? false,
            ...array_filter([
                'daily_start_time' => $data['daily_start_time'] ?? null,
                'daily_end_time' => $data['daily_end_time'] ?? null,
            ]),
        ]);

        return response()->json($trip, 201);
    }

    public function show(Request $request, Trip $trip)
    {
        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        // Hasil itinerary (D1) dan peta live (E1) butuh nama/koordinat/foto
        // tiap stop dan hotel sekaligus, tanpa satu request per tempat.
        $placeColumns = 'places_id,name,type,lat,lng,address,kecamatan,photo_url,estimated_visit_minutes,is_outdoor';

        $trip->load([
            'days' => fn ($dayQuery) => $dayQuery->orderBy('day_number'),
            'days.items' => fn ($itemQuery) => $itemQuery->orderBy('visit_order'),
            "days.items.place:{$placeColumns}",
            "hotelPlace:{$placeColumns}",
        ]);

        return response()->json($trip);
    }

    /**
     * F008 langkah 3: minat (trip_interest_category) + bobot 4 kriteria
     * dalam satu request - dua hal yang disatukan sengaja, sesuai flow di
     * mobile (satu layar). US1: 0 slider disentuh tetap submit dengan
     * bobot sama rata, tidak diblokir.
     */
    public function weights(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $data = $request->validate([
            'category_ids' => ['required', 'array', 'min:1'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')->whereNull('deleted_at')],
            'rating_kategori' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_jarak' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_anggaran' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_rating' => ['required', 'numeric', 'min:0', 'max:10'],
        ]);

        $sum = $data['rating_kategori'] + $data['rating_jarak'] + $data['rating_anggaran'] + $data['rating_rating'];

        if ($sum > 0) {
            $weights = [
                'weight_kategori' => $data['rating_kategori'] / $sum,
                'weight_jarak' => $data['rating_jarak'] / $sum,
                'weight_anggaran' => $data['rating_anggaran'] / $sum,
                'weight_rating' => $data['rating_rating'] / $sum,
            ];
        } else {
            $weights = [
                'weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25,
            ];
        }

        DB::transaction(function () use ($trip, $data, $weights) {
            $trip->interestCategories()->sync($data['category_ids']);
            $trip->update($weights);
        });

        return response()->json($trip->fresh(['interestCategories']));
    }

    /**
     * F008 langkah 4: set hotel - dari katalog (places_id) atau custom pin.
     */
    public function hotel(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $hasPlacesId = $request->filled('places_id');

        $data = $request->validate([
            'places_id' => ['nullable', 'integer', Rule::exists('places', 'places_id')->whereNull('deleted_at')],
            'custom_name' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'string', 'max:255'],
            'custom_lat' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'numeric', 'between:-90,90'],
            'custom_lng' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'numeric', 'between:-180,180'],
        ]);

        if (! empty($data['places_id'])) {
            $trip->update([
                'hotel_places_id' => $data['places_id'],
                'hotel_custom_name' => null, 'hotel_lat' => null, 'hotel_lng' => null,
            ]);
        } else {
            $trip->update([
                'hotel_places_id' => null,
                'hotel_custom_name' => $data['custom_name'],
                'hotel_lat' => $data['custom_lat'],
                'hotel_lng' => $data['custom_lng'],
            ]);
        }

        return response()->json($trip->fresh());
    }

    /**
     * F008 langkah 4: top-3 rekomendasi hotel TOPSIS. Kosong kalau trip
     * sudah pakai has_own_hotel (tidak butuh rekomendasi).
     */
    public function hotelOptions(Request $request, Trip $trip, HotelRecommender $recommender)
    {
        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        if ($trip->has_own_hotel) {
            return response()->json(['data' => []]);
        }

        try {
            $options = $recommender->topThree($trip);
        } catch (RuntimeException $exception) {
            throw ValidationException::withMessages(['hotel' => [$exception->getMessage()]]);
        }

        return response()->json([
            'data' => $options->map(fn ($option) => [
                'places_id' => $option['place']->places_id,
                'name' => $option['place']->name,
                'address' => $option['place']->address,
                'lat' => (float) $option['place']->lat,
                'lng' => (float) $option['place']->lng,
                'photo_url' => $option['place']->photo_url,
                'rating' => $option['place']->ratingBlend(),
                'topsis_score' => $option['topsis_score'],
            ])->values(),
        ]);
    }

    /**
     * F008: K-Means + TOPSIS + Nearest-Neighbor + Routes API -> itinerary.
     */
    public function generate(Request $request, Trip $trip, ItineraryGenerator $generator)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        try {
            $result = $generator->generate($trip);
        } catch (RuntimeException $exception) {
            throw ValidationException::withMessages(['trip' => [$exception->getMessage()]]);
        }

        return response()->json([
            'trip' => $trip->fresh(),
            'days' => collect($result['days'])->map(fn ($day) => [
                'itinerary_days_id' => $day['day']->itinerary_days_id,
                'day_number' => $day['day']->day_number,
                'tidak_muat' => $day['tidak_muat'],
                'padat' => $day['padat'],
                'items' => $day['day']->items->map(fn ($item) => [
                    'itinerary_items_id' => $item->itinerary_items_id,
                    'places_id' => $item->places_id,
                    'visit_order' => $item->visit_order,
                    'topsis_score' => $item->topsis_score,
                    'source' => $item->source,
                    'polyline_to_here' => $item->polyline_to_here,
                ])->values(),
            ])->values(),
            'dropped_wishlist_places' => $result['dropped_wishlist_places'],
        ]);
    }

    /**
     * F011: edit trip tersimpan (PRD audit 2026-10-10 - endpoint ini
     * sebelumnya tidak ada walau Section 12/13 mengasumsikan trip bisa
     * diedit). Owner-only. Kalau field yang menentukan susunan hari berubah
     * (num_days, budget_total, jam harian) dan itinerary sudah ada, itinerary
     * lama dibuang - design spec Section 13 langkah 9 memang "regenerate
     * penuh"; mobile memanggil POST /generate lagi setelah ini. start_date
     * dan title tidak membuang itinerary.
     */
    public function update(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $data = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'num_days' => ['sometimes', 'integer', 'min:1'],
            'budget_total' => ['sometimes', 'integer', 'min:1'],
            'start_date' => ['sometimes', 'date'],
            'daily_start_time' => ['sometimes', 'date_format:H:i'],
            'daily_end_time' => ['sometimes', 'date_format:H:i'],
        ]);

        $dailyStart = $data['daily_start_time'] ?? substr((string) $trip->daily_start_time, 0, 5);
        $dailyEnd = $data['daily_end_time'] ?? substr((string) $trip->daily_end_time, 0, 5);

        if ($dailyEnd <= $dailyStart) {
            throw ValidationException::withMessages([
                'daily_end_time' => ['Jam selesai harus setelah jam mulai.'],
            ]);
        }

        $structural = ['num_days', 'budget_total', 'daily_start_time', 'daily_end_time'];
        $itineraryCleared = false;

        DB::transaction(function () use ($trip, $data, $structural, &$itineraryCleared) {
            $trip->fill($data);
            $structuralChanged = collect($structural)->contains(fn ($field) => $trip->isDirty($field));
            $trip->save();

            if ($structuralChanged && $trip->days()->exists()) {
                $trip->days()->delete();
                $itineraryCleared = true;
            }
        });

        return response()->json([
            ...$trip->fresh()->toArray(),
            'itinerary_cleared' => $itineraryCleared,
        ]);
    }

    /**
     * F011: hapus trip tersimpan - soft delete (trips.deleted_at),
     * riwayat kunjungan yang sudah pernah dilihat viewer dkk tetap utuh
     * di database, cuma hilang dari daftar/pencarian aktif.
     */
    public function destroy(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $trip->delete();

        return response()->json(['message' => 'Trip dihapus.']);
    }

    /**
     * F017 (docs/prd design spec Section 10) - generate/ambil share_token
     * publik. Idempotent - link yang sama terus dipakai sampai sengaja
     * di-reset, bukan generate ulang tiap tap.
     */
    public function storeShareLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if ($trip->share_token === null) {
            $trip->update(['share_token' => $this->generateUniqueShareToken()]);
        }

        return response()->json(['share_token' => $trip->share_token]);
    }

    /**
     * Matikan link publik - link lama langsung mati buat siapapun yang
     * masih pegang, beda dari viewer_invite_token (F015) yang cuma
     * menutup jalur masuk baru tanpa mencabut akses yang sudah join
     * (share link anon tidak punya baris akses yang bisa "sudah join").
     */
    public function destroyShareLink(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $trip->update(['share_token' => null]);

        return response()->json(['message' => 'Link publik dimatikan.']);
    }

    private function generateUniqueShareToken(): string
    {
        do {
            $token = Str::random(32);
        } while (Trip::where('share_token', $token)->exists());

        return $token;
    }
}
