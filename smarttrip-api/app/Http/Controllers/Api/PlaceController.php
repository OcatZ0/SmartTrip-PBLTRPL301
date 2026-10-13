<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PlaceDetailResource;
use App\Http\Resources\PlaceResource;
use App\Models\ItineraryDay;
use App\Models\Place;
use App\Services\Itinerary\Haversine;
use App\Services\Itinerary\KMeans;
use Illuminate\Http\Request;
use Illuminate\Pagination\LengthAwarePaginator;

/**
 * F005-F006: katalog tempat wisata (browse/search publik) dan detail
 * tempat. docs/prd design spec Section 12: GET /api/places?search=&
 * category=&kecamatan=&type=, GET /api/places/{id} - keduanya publik.
 * type=lodging dipakai pencarian hotel di trip setup (C4).
 * near_itinerary_day (F0010 - Swap, "cari lainnya" manual) urutkan hasil
 * dari yang terdekat ke hari itinerary tersebut.
 */
class PlaceController extends Controller
{
    /**
     * near_itinerary_day butuh jarak Haversine per baris buat urut - tidak
     * portable sebagai satu query SQL lintas pgsql/sqlite, jadi diurutkan
     * di PHP atas maksimal sekian baris (cukup buat skala katalog awal
     * proyek ini, bukan solusi jangka panjang buat katalog besar).
     */
    private const NEAR_DAY_SCAN_LIMIT = 500;

    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $query = Place::query()
            ->where('business_status', '!=', 'closed_permanently')
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower($request->string('search')->trim()).'%';
                $query->whereRaw('LOWER(name) LIKE ?', [$term]);
            })
            ->when($request->filled('category'), function ($query) use ($request) {
                $slug = $request->string('category')->trim();
                $query->whereHas('categories', fn ($q) => $q->where('slug', $slug));
            })
            ->when($request->filled('type'), fn ($query) => $query->where('type', $request->string('type')->trim()))
            ->when($request->filled('kecamatan'), function ($query) use ($request) {
                $kecamatan = mb_strtolower($request->string('kecamatan')->trim());
                $query->whereRaw('LOWER(kecamatan) = ?', [$kecamatan]);
            })
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->with('categories');

        if ($request->filled('near_itinerary_day')) {
            return $this->paginateNearDay($query, (int) $request->integer('near_itinerary_day'), $perPage, $request);
        }

        return PlaceResource::collection($query->orderBy('places_id')->paginate($perPage));
    }

    private function paginateNearDay($query, int $dayId, int $perPage, Request $request)
    {
        $day = ItineraryDay::with(['trip', 'items.place'])->find($dayId);

        if ($day === null) {
            abort(404, 'Hari itinerary tidak ditemukan.');
        }

        $points = $day->items
            ->filter(fn ($item) => $item->place !== null)
            ->map(fn ($item) => ['lat' => (float) $item->place->lat, 'lng' => (float) $item->place->lng])
            ->values()
            ->all();

        $reference = $points !== [] ? KMeans::centroid($points) : $day->trip->hotelCoordinates();

        $places = $query->limit(self::NEAR_DAY_SCAN_LIMIT)->get();

        if ($reference !== null) {
            $places = $places->sortBy(fn ($place) => Haversine::km(
                $reference['lat'], $reference['lng'], (float) $place->lat, (float) $place->lng
            ))->values();
        }

        $page = max((int) $request->integer('page', 1), 1);
        $sliced = $places->slice(($page - 1) * $perPage, $perPage)->values();

        $paginator = new LengthAwarePaginator(
            $sliced, $places->count(), $perPage, $page,
            ['path' => $request->url(), 'query' => $request->query()]
        );

        return PlaceResource::collection($paginator);
    }

    public function show(Place $place)
    {
        $place->loadAvg('reviews', 'rating')
            ->loadCount('reviews')
            ->load(['categories', 'photos', 'reviews' => fn ($q) => $q->with('user:users_id,name')->latest()]);

        return new PlaceDetailResource($place);
    }
}
