<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PlaceDetailResource;
use App\Http\Resources\PlaceResource;
use App\Models\Place;
use Illuminate\Http\Request;
use Knuckles\Scribe\Attributes\Endpoint;
use Knuckles\Scribe\Attributes\Group;
use Knuckles\Scribe\Attributes\Unauthenticated;

/**
 * F005-F006: katalog tempat wisata (browse/search publik) dan detail
 * tempat. docs/prd design spec Section 12: GET /api/places?search=&
 * category=&kecamatan=&type=, GET /api/places/{id} - keduanya publik.
 * type=lodging dipakai pencarian hotel di trip setup (C4).
 * GET /api/places/kecamatan mengisi pilihan filter kecamatan di katalog.
 */
#[Group('Katalog Tempat')]
class PlaceController extends Controller
{
    #[Endpoint('Cari tempat', 'Filter search, category (slug), kecamatan, dan type (attraction, culinary, lodging). Hasil dipaginasi, per_page maksimal 50.')]
    #[Unauthenticated]
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $query = Place::query()
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower($request->string('search')->trim()).'%';
                // Also the place's own search keywords (set by the admin or
                // Gemini), e.g. "snorkeling" finds Pulau Abang even though the
                // word is not in its name.
                $query->where(fn ($match) => $match
                    ->whereRaw('LOWER(name) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(search_keywords) LIKE ?', [$term]));
            })
            ->when($request->filled('category'), function ($query) use ($request) {
                $slug = $request->string('category')->trim();
                $query->whereHas('categories', fn ($categoryQuery) => $categoryQuery->where('slug', $slug));
            })
            ->when($request->filled('type'), fn ($query) => $query->where('type', $request->string('type')->trim()))
            ->when($request->filled('kecamatan'), function ($query) use ($request) {
                $kecamatan = mb_strtolower($request->string('kecamatan')->trim());
                $query->whereRaw('LOWER(TRIM(kecamatan)) = ?', [$kecamatan]);
            })
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->with('categories');

        return PlaceResource::collection($query->orderBy('places_id')->paginate($perPage));
    }

    /**
     * Kecamatan that have at least one open place, for the catalog's
     * kecamatan filter. Grouped case-insensitively because admins type the
     * value by hand, matching the case-insensitive ?kecamatan= filter.
     */
    #[Endpoint('Daftar kecamatan', 'Kecamatan yang punya tempat, untuk pilihan filter katalog.')]
    #[Unauthenticated]
    public function kecamatan()
    {
        $rows = Place::query()
            ->whereNotNull('kecamatan')
            ->where('kecamatan', '!=', '')
            ->selectRaw('kecamatan, COUNT(*) as places_count')
            ->groupBy('kecamatan')
            ->orderBy('kecamatan')
            ->get();

        $kecamatan = [];
        foreach ($rows as $row) {
            $name = trim($row->kecamatan);
            $key = mb_strtolower($name);
            if (isset($kecamatan[$key])) {
                $kecamatan[$key]['places_count'] += (int) $row->places_count;

                continue;
            }
            $kecamatan[$key] = ['name' => $name, 'places_count' => (int) $row->places_count];
        }

        return response()->json(['data' => collect($kecamatan)->sortBy('name', SORT_NATURAL | SORT_FLAG_CASE)->values()]);
    }

    #[Endpoint('Detail tempat', 'Info lengkap, foto, dan ulasan satu tempat.')]
    #[Unauthenticated]
    public function show(Place $place)
    {
        $place->loadAvg('reviews', 'rating')
            ->loadCount('reviews')
            ->load(['categories', 'photos', 'reviews' => fn ($reviewQuery) => $reviewQuery->with('user:users_id,name')->latest()]);

        return new PlaceDetailResource($place);
    }
}
