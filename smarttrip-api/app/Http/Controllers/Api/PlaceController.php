<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PlaceDetailResource;
use App\Http\Resources\PlaceResource;
use App\Models\Place;
use Illuminate\Http\Request;

/**
 * F005-F006: katalog tempat wisata (browse/search publik) dan detail
 * tempat. docs/prd design spec Section 12: GET /api/places?search=&
 * category=&kecamatan=, GET /api/places/{id} - keduanya publik.
 */
class PlaceController extends Controller
{
    public function index(Request $request)
    {
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 50);

        $places = Place::query()
            ->where('business_status', '!=', 'closed_permanently')
            ->when($request->filled('search'), function ($query) use ($request) {
                $term = '%'.mb_strtolower($request->string('search')->trim()).'%';
                $query->whereRaw('LOWER(name) LIKE ?', [$term]);
            })
            ->when($request->filled('category'), function ($query) use ($request) {
                $slug = $request->string('category')->trim();
                $query->whereHas('categories', fn ($q) => $q->where('slug', $slug));
            })
            ->when($request->filled('kecamatan'), function ($query) use ($request) {
                $kecamatan = mb_strtolower($request->string('kecamatan')->trim());
                $query->whereRaw('LOWER(kecamatan) = ?', [$kecamatan]);
            })
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->with('categories')
            ->orderBy('places_id')
            ->paginate($perPage);

        return PlaceResource::collection($places);
    }

    public function show(Place $place)
    {
        $place->loadAvg('reviews', 'rating')
            ->loadCount('reviews')
            ->load(['categories', 'photos']);

        return new PlaceDetailResource($place);
    }
}
