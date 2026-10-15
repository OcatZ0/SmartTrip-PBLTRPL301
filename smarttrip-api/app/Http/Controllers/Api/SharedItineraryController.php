<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
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
 * koordinat presisi hotel custom pin.
 */
class SharedItineraryController extends Controller
{
    public function show(string $shareToken)
    {
        $trip = Trip::where('share_token', $shareToken)->first();

        if (! $trip) {
            abort(404);
        }

        $trip->load(['days' => fn ($dayQuery) => $dayQuery->orderBy('day_number'), 'days.items' => fn ($itemQuery) => $itemQuery->orderBy('visit_order'), 'days.items.place']);

        return response()->json([
            'title' => $trip->title,
            'num_days' => $trip->num_days,
            'start_date' => $trip->start_date,
            'hotel' => $this->hotelPayload($trip),
            'days' => $trip->days->map(fn ($day) => [
                'day_number' => $day->day_number,
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
     * Hotel dari katalog places (lokasi publik) aman ditampilkan apa
     * adanya. Custom pin (lokasi pribadi pemilik) - sembunyikan koordinat
     * presisi dan nama custom-nya, tampilkan label generik saja.
     */
    private function hotelPayload(Trip $trip): ?array
    {
        if ($trip->hotel_places_id !== null) {
            $place = $trip->hotelPlace()->first();

            return $place ? [
                'type' => 'catalog',
                'name' => $place->name,
                'address' => $place->address,
                'lat' => (float) $place->lat,
                'lng' => (float) $place->lng,
            ] : null;
        }

        if ($trip->hotel_lat !== null && $trip->hotel_lng !== null) {
            return ['type' => 'custom', 'label' => 'Hotel'];
        }

        return null;
    }
}
