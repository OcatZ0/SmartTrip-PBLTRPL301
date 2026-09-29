<?php

namespace App\Services\Itinerary;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * docs/prd design spec Section 7 langkah 6e - satu call computeRoutes per
 * hari, waypoint hotel -> stop 1 -> ... -> hotel, simpan tiap leg ke
 * polyline_to_here stop tujuannya masing-masing (bukan satu polyline
 * gabungan).
 */
class GoogleRoutesClient
{
    /**
     * @param  array<int, array{lat: float, lng: float}>  $waypoints  urut: titik awal ... titik akhir, minimal 2
     * @return array<int, array{duration_seconds: int, polyline: string}> satu entri per leg (n-1 leg buat n waypoint)
     */
    public function computeRoute(array $waypoints): array
    {
        if (count($waypoints) < 2) {
            throw new RuntimeException('computeRoute butuh minimal 2 waypoint.');
        }

        $origin = array_shift($waypoints);
        $destination = array_pop($waypoints);
        $intermediates = $waypoints;

        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
            'X-Goog-Api-Key' => config('services.google.routes_api_key'),
            'X-Goog-FieldMask' => 'routes.legs.duration,routes.legs.polyline.encodedPolyline,routes.legs.distanceMeters',
        ])->post('https://routes.googleapis.com/directions/v2:computeRoutes', [
            'origin' => ['location' => ['latLng' => ['latitude' => $origin['lat'], 'longitude' => $origin['lng']]]],
            'destination' => ['location' => ['latLng' => ['latitude' => $destination['lat'], 'longitude' => $destination['lng']]]],
            'intermediates' => array_map(fn ($point) => [
                'location' => ['latLng' => ['latitude' => $point['lat'], 'longitude' => $point['lng']]],
            ], $intermediates),
            'travelMode' => 'DRIVE',
        ]);

        if ($response->failed()) {
            throw new RuntimeException('Google Routes API gagal: '.$response->body());
        }

        $legs = $response->json('routes.0.legs', []);

        return array_map(fn (array $leg) => [
            'duration_seconds' => (int) rtrim($leg['duration'] ?? '0s', 's'),
            'polyline' => $leg['polyline']['encodedPolyline'] ?? '',
        ], $legs);
    }
}
