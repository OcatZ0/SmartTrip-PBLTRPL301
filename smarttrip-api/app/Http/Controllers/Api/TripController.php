<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use App\Services\Itinerary\HotelRecommender;
use App\Services\Itinerary\ItineraryGenerator;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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

        $trip->load(['days' => fn ($q) => $q->orderBy('day_number'), 'days.items' => fn ($q) => $q->orderBy('visit_order')]);

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
        } catch (RuntimeException $e) {
            throw ValidationException::withMessages(['hotel' => [$e->getMessage()]]);
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
        } catch (RuntimeException $e) {
            throw ValidationException::withMessages(['trip' => [$e->getMessage()]]);
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
}
