<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\WishlistItemResource;
use App\Models\Trip;
use App\Models\TripWishlistPlace;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\ProhibitedIf;

/**
 * F007: wishlist tempat wisata - docs/prd design spec Section 12.
 * Tambah/hapus wishlist owner-only; lihat wishlist owner ATAU viewer
 * (Section 9). Item bisa dari katalog (places_id) atau pin custom
 * (custom_name/custom_lat/custom_lng/custom_visit_minutes) - mutually
 * exclusive, sama seperti CHECK constraint di migration.
 */
class WishlistController extends Controller
{
    public function index(Request $request, Trip $trip)
    {
        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        $items = $trip->wishlistPlaces()
            ->with(['place' => fn ($query) => $query->withAvg('reviews', 'rating')->withCount('reviews')])
            ->get();

        return WishlistItemResource::collection($items);
    }

    public function store(Request $request, Trip $trip)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $hasPlacesId = $request->filled('places_id');

        $data = $request->validate([
            'places_id' => [
                'nullable', 'integer',
                Rule::exists('places', 'places_id')->whereNull('deleted_at'),
            ],
            'custom_name' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'string', 'max:255'],
            'custom_lat' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'numeric', 'between:-90,90'],
            'custom_lng' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'numeric', 'between:-180,180'],
            'custom_visit_minutes' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'integer', 'min:1'],
        ]);

        if (! empty($data['places_id'])) {
            // US3: menambah tempat yang sama dua kali = no-op, bukan error.
            $item = TripWishlistPlace::firstOrCreate([
                'trips_id' => $trip->trips_id,
                'places_id' => $data['places_id'],
            ]);
            $status = $item->wasRecentlyCreated ? 201 : 200;
        } else {
            $item = TripWishlistPlace::create([
                'trips_id' => $trip->trips_id,
                'custom_name' => $data['custom_name'],
                'custom_lat' => $data['custom_lat'],
                'custom_lng' => $data['custom_lng'],
                'custom_visit_minutes' => $data['custom_visit_minutes'],
            ]);
            $status = 201;
        }

        $item->load(['place' => fn ($query) => $query->withAvg('reviews', 'rating')->withCount('reviews')]);

        return (new WishlistItemResource($item))->response()->setStatusCode($status);
    }

    public function destroy(Request $request, Trip $trip, TripWishlistPlace $wishlist)
    {
        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        if ($wishlist->trips_id !== $trip->trips_id) {
            abort(404);
        }

        $wishlist->delete();

        return response()->json(['message' => 'Item wishlist dihapus.']);
    }
}
