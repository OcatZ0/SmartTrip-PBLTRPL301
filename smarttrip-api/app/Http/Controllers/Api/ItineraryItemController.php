<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Services\Itinerary\ItineraryGenerator;
use App\Services\Itinerary\SwapCandidateFinder;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;
use RuntimeException;

/**
 * F0010 (Swap) - docs/prd design spec Section 7 langkah 7 & Section 12.
 */
class ItineraryItemController extends Controller
{
    public function swapCandidates(Request $request, ItineraryItem $itineraryItem, SwapCandidateFinder $finder)
    {
        $trip = $itineraryItem->day->trip;

        if (! $trip->isReadableBy($request->user())) {
            abort(403);
        }

        $limit = min(max((int) $request->integer('limit', 10), 1), 50);

        $candidates = $finder->rankedCandidates($itineraryItem)->take($limit);

        return response()->json([
            'data' => $candidates->map(fn ($candidate) => [
                'places_id' => $candidate['place']->places_id,
                'name' => $candidate['place']->name,
                'type' => $candidate['place']->type,
                'photo_url' => $candidate['place']->photo_url,
                'lat' => (float) $candidate['place']->lat,
                'lng' => (float) $candidate['place']->lng,
                'rating' => $candidate['place']->ratingBlend(),
                // The weather swap (F025) puts indoor places first.
                'is_outdoor' => (bool) $candidate['place']->is_outdoor,
                'topsis_score' => $candidate['topsis_score'],
            ])->values(),
        ]);
    }

    public function update(Request $request, ItineraryItem $itineraryItem, SwapCandidateFinder $finder, ItineraryGenerator $generator)
    {
        $day = $itineraryItem->day;
        $trip = $day->trip;

        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $data = $request->validate([
            'places_id' => ['required', 'integer', Rule::exists('places', 'places_id')->whereNull('deleted_at')],
        ]);

        $usedElsewhere = ItineraryItem::query()
            ->whereHas('day', fn ($dayQuery) => $dayQuery->where('trips_id', $trip->trips_id))
            ->where('itinerary_items_id', '!=', $itineraryItem->itinerary_items_id)
            ->where('places_id', $data['places_id'])
            ->exists();

        if ($usedElsewhere) {
            return response()->json([
                'message' => 'Tempat ini sudah dipakai di hari lain pada trip yang sama.',
                'errors' => ['places_id' => ['Tempat ini sudah dipakai di hari lain pada trip yang sama.']],
            ], 422);
        }

        $newPlace = Place::findOrFail($data['places_id']);

        $topsisScore = $finder->scoreFor($itineraryItem, $newPlace);

        try {
            DB::transaction(function () use ($itineraryItem, $data, $topsisScore, $generator, $trip, $day) {
                $itineraryItem->update([
                    'places_id' => $data['places_id'],
                    'topsis_score' => $topsisScore,
                    'visited_at' => null,
                    'custom_name' => null,
                    'custom_lat' => null,
                    'custom_lng' => null,
                    'custom_visit_minutes' => null,
                ]);

                $generator->resequenceDay($trip, $day);
            });
        } catch (RuntimeException $exception) {
            throw ValidationException::withMessages(['places_id' => [$exception->getMessage()]]);
        }

        $day->load(['items' => fn ($itemQuery) => $itemQuery->orderBy('visit_order')]);

        return response()->json([
            'itinerary_days_id' => $day->itinerary_days_id,
            'items' => $day->items->map(fn ($item) => [
                'itinerary_items_id' => $item->itinerary_items_id,
                'places_id' => $item->places_id,
                'visit_order' => $item->visit_order,
                'topsis_score' => $item->topsis_score,
                'source' => $item->source,
                'polyline_to_here' => $item->polyline_to_here,
                'visited_at' => $item->visited_at,
            ])->values(),
        ]);
    }

    /**
     * F013 (docs/prd design spec Section 8 & 12) - tandai kunjungan sebuah
     * stop. Dipanggil otomatis dari mobile saat geofence entry terpicu, atau
     * manual (tombol/long-press di peta) kalau geofence tidak kepicu.
     * Toggle: server tidak percaya body request untuk menentukan status -
     * kalau sudah visited maka request ini membatalkannya (set null),
     * kalau belum maka menandainya visited (set now()). Tidak ada
     * verifikasi lokasi device di sisi server (bukan sistem anti-fraud,
     * cuma buat visualisasi progres - lihat Section 8).
     */
    public function visit(Request $request, ItineraryItem $itineraryItem)
    {
        $trip = $itineraryItem->day->trip;

        if (! $trip->isOwnedBy($request->user())) {
            abort(403);
        }

        $itineraryItem->update([
            'visited_at' => $itineraryItem->visited_at ? null : Carbon::now(),
        ]);

        return response()->json([
            'itinerary_items_id' => $itineraryItem->itinerary_items_id,
            'visited_at' => $itineraryItem->visited_at,
        ]);
    }
}
