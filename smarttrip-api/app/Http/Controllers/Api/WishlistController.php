<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\WishlistItemResource;
use App\Models\Trip;
use App\Models\TripWishlistPlace;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\ProhibitedIf;
use Knuckles\Scribe\Attributes\Endpoint;
use Knuckles\Scribe\Attributes\Group;

/**
 * F007: wishlist tempat wisata - docs/prd design spec Section 12.
 * Tambah/hapus wishlist owner-only; lihat wishlist owner ATAU viewer
 * (Section 9). Item bisa dari katalog (places_id) atau pin custom
 * (custom_name/custom_lat/custom_lng/custom_visit_minutes) - mutually
 * exclusive, sama seperti CHECK constraint di migration.
 */
#[Group('Wishlist Trip', 'Tempat dan pin yang ingin dikunjungi dalam satu trip, maksimal 100 item.')]
class WishlistController extends Controller
{
    /**
     * Generation orders every wishlist item against every candidate, so an
     * unbounded list lets one trip tie up the server; the app's own picks
     * stay far below this.
     */
    private const MAX_ITEMS = 100;

    /**
     * 12 hours; the app offers 30 to 180 minutes.
     */
    private const MAX_VISIT_MINUTES = 720;

    #[Endpoint('Lihat wishlist trip', 'Untuk pemilik dan viewer.')]
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

    #[Endpoint('Tambah ke wishlist trip', 'Tempat dari katalog (places_id) atau pin sendiri (custom_name, custom_lat, custom_lng, custom_visit_minutes maksimal 720).')]
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
            'custom_visit_minutes' => ['required_without:places_id', new ProhibitedIf($hasPlacesId), 'integer', 'min:1', 'max:'.self::MAX_VISIT_MINUTES],
        ]);

        $alreadyListed = ! empty($data['places_id'])
            && $trip->wishlistPlaces()->where('places_id', $data['places_id'])->exists();

        if (! $alreadyListed && $trip->wishlistPlaces()->count() >= self::MAX_ITEMS) {
            return response()->json([
                'message' => 'Wishlist trip ini sudah berisi '.self::MAX_ITEMS.' tempat, hapus beberapa dulu.',
                'errors' => ['places_id' => ['Wishlist trip ini sudah berisi '.self::MAX_ITEMS.' tempat, hapus beberapa dulu.']],
            ], 422);
        }

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

    #[Endpoint('Hapus dari wishlist trip', 'Hanya pemilik trip.')]
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
