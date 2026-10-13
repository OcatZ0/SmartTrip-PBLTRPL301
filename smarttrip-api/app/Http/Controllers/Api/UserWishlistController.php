<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\PlaceResource;
use App\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * F007 revisi 2026-10-13: wishlist pribadi user (tombol hati di katalog B1,
 * tab Wishlist B3), terpisah dari wishlist per trip (WishlistController)
 * yang dipakai generate. Tidak ada paginasi: satu user wajarnya cuma
 * menyimpan puluhan tempat.
 */
class UserWishlistController extends Controller
{
    public function index(Request $request)
    {
        $places = $request->user()->wishlistPlaces()
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->with('categories')
            ->orderByPivot('added_at', 'desc')
            ->get();

        return PlaceResource::collection($places);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'places_id' => ['required', 'integer', Rule::exists('places', 'places_id')->whereNull('deleted_at')],
        ]);

        // Menyimpan tempat yang sama dua kali = no-op, bukan error.
        $changes = $request->user()->wishlistPlaces()->syncWithoutDetaching([$data['places_id']]);
        $added = $changes['attached'] !== [];

        return response()->json(
            ['message' => $added ? 'Tempat disimpan ke wishlist.' : 'Tempat sudah ada di wishlist.'],
            $added ? 201 : 200
        );
    }

    public function destroy(Request $request, Place $place)
    {
        $request->user()->wishlistPlaces()->detach($place->places_id);

        return response()->json(['message' => 'Tempat dihapus dari wishlist.']);
    }
}
