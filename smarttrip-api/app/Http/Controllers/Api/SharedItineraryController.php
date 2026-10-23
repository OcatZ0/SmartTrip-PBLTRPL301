<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ItineraryDay;
use App\Models\Trip;

/**
 * F017 (docs/prd design spec Section 10) - satu-satunya endpoint publik
 * (tanpa Sanctum sama sekali) yang menyajikan data sebuah trip milik user
 * tertentu. Whitelist ketat, BUKAN blacklist - field baru yang ditambah
 * ke trips/itinerary_items di masa depan defaultnya TIDAK muncul di sini
 * kecuali sengaja ditambahkan, karena response dibangun manual field per
 * field, bukan lewat response()->json($trip) langsung.
 *
 * WAJIB DIKECUALIKAN: visited_at, identitas pemilik (users.*), budget_total,
 * koordinat presisi titik awal/akhir custom pin.
 */
class SharedItineraryController extends Controller
{
    public function show(string $shareToken)
    {
        $trip = Trip::where('share_token', $shareToken)->first();

        if (! $trip) {
            abort(404);
        }

        $trip->load(['days' => fn ($dayQuery) => $dayQuery->orderBy('day_number'), 'days.items' => fn ($itemQuery) => $itemQuery->orderBy('visit_order'), 'days.items.place', 'days.startPlace', 'days.endPlace']);

        return response()->json([
            'title' => $trip->title,
            'num_days' => $trip->num_days,
            'start_date' => $trip->start_date,
            'hotel' => $this->pointPayload($trip->days->first()?->startPoint()),
            'days' => $trip->days->map(fn (ItineraryDay $day) => [
                'day_number' => $day->day_number,
                'start' => $this->pointPayload($day->startPoint()),
                'end' => $this->pointPayload($day->endPoint()),
                'items' => $day->items->map(fn ($item) => [
                    'visit_order' => $item->visit_order,
                    'name' => $item->place?->name,
                    'address' => $item->place?->address,
                    'photo_url' => $item->place?->photo_url,
                    'lat' => $item->place ? (float) $item->place->lat : null,
                    'lng' => $item->place ? (float) $item->place->lng : null,
                    'estimated_visit_minutes' => $item->place?->estimated_visit_minutes,
                    'polyline_to_here' => $item->polyline_to_here,
                ])->values(),
            ])->values(),
        ]);
    }

    /**
     * A catalog place (a public location) is shown as it is. A custom pin
     * (the owner's private location) shows a generic label only, without its
     * exact coordinates or its custom name.
     *
     * @param  array{lat: float, lng: float, name: ?string, places_id: ?int}|null  $point
     */
    private function pointPayload(?array $point): ?array
    {
        if ($point === null) {
            return null;
        }

        if ($point['places_id'] !== null) {
            return ['type' => 'catalog', 'name' => $point['name'], 'lat' => $point['lat'], 'lng' => $point['lng']];
        }

        return ['type' => 'custom', 'label' => 'Hotel'];
    }
}
