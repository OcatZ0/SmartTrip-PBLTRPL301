<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\PlaceReview;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * F014 (docs/prd design spec Section 6 & 12) - review terbuka, siapa saja
 * yang login bisa review tempat manapun kapan saja, tidak perlu bukti
 * kunjungan. 1 user cuma boleh 1 review per tempat (unique(users_id,
 * places_id) di skema) - review ulang berarti edit (PATCH), bukan baris
 * baru.
 */
class ReviewController extends Controller
{
    public function store(Request $request, Place $place)
    {
        $existing = PlaceReview::query()
            ->where('places_id', $place->places_id)
            ->where('users_id', $request->user()->users_id)
            ->first();

        if ($existing) {
            return response()->json([
                'message' => 'Kamu sudah pernah memberi ulasan untuk tempat ini. Ubah ulasan yang sudah ada.',
                'errors' => ['place_reviews_id' => [$existing->place_reviews_id]],
            ], 422);
        }

        $data = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:2000'],
            'itinerary_items_id' => ['nullable', 'integer', Rule::exists('itinerary_items', 'itinerary_items_id')],
        ]);

        if (! empty($data['itinerary_items_id'])) {
            $this->assertItineraryItemBelongsToPlaceAndUser($data['itinerary_items_id'], $place, $request->user());
        }

        $review = PlaceReview::create([
            'places_id' => $place->places_id,
            'users_id' => $request->user()->users_id,
            'rating' => $data['rating'],
            'comment' => $data['comment'] ?? null,
            'itinerary_items_id' => $data['itinerary_items_id'] ?? null,
        ]);

        return response()->json($review, 201);
    }

    public function update(Request $request, PlaceReview $review)
    {
        if ($review->users_id !== $request->user()->users_id) {
            abort(403);
        }

        $data = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:2000'],
        ]);

        $review->update($data);

        return response()->json($review->fresh());
    }

    public function destroy(Request $request, PlaceReview $review)
    {
        if ($review->users_id !== $request->user()->users_id) {
            abort(403);
        }

        $review->delete();

        return response()->json(['message' => 'Review dihapus.']);
    }

    /**
     * itinerary_items_id cuma boleh dipasang kalau stop itu memang punya
     * tempat yang sama dengan yang direview, dan itinerary-nya milik user
     * yang submit - mencegah user menempel review ke stop trip orang lain.
     */
    private function assertItineraryItemBelongsToPlaceAndUser(int $itineraryItemsId, Place $place, $user): void
    {
        $item = ItineraryItem::with('day.trip')->findOrFail($itineraryItemsId);

        if ($item->places_id !== $place->places_id || ! $item->day->trip->isOwnedBy($user)) {
            abort(422, 'itinerary_items_id tidak valid untuk review ini.');
        }
    }
}
