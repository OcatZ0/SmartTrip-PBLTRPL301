<?php

namespace App\Services\Itinerary;

use App\Services\ApiUsage;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Road routing for design spec Section 7 langkah 6e, replacing the Google
 * Routes API (2026-10-13: the Google project could not enable billing).
 * OpenRouteService's free Standard plan allows 2,000 directions a day
 * without a credit card. One call per day: hotel -> stop 1 -> ... -> hotel,
 * and each leg is stored on its destination stop as polyline_to_here.
 *
 * ORS returns one geometry for the whole route plus the index of every
 * waypoint inside it (way_points), so the legs are cut out of it here.
 */
class OpenRouteServiceClient
{
    private const ENDPOINT = 'https://api.openrouteservice.org/v2/directions/driving-car/geojson';

    private const TIMEOUT_SECONDS = 30;

    /**
     * @param  array<int, array{lat: float, lng: float}>  $waypoints  urut: titik awal ... titik akhir, minimal 2
     * @return array<int, array{duration_seconds: int, polyline: string}> satu entri per leg (n-1 leg buat n waypoint)
     */
    public function computeRoute(array $waypoints): array
    {
        if (count($waypoints) < 2) {
            throw new RuntimeException('computeRoute butuh minimal 2 waypoint.');
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => (string) config('services.openrouteservice.api_key'),
                'Content-Type' => 'application/json',
            ])
                ->timeout(self::TIMEOUT_SECONDS)
                ->post(self::ENDPOINT, [
                    // ORS takes [lng, lat], the reverse of everything else here.
                    'coordinates' => array_map(fn (array $point) => [$point['lng'], $point['lat']], $waypoints),
                ]);
        } catch (ConnectionException $exception) {
            throw new RuntimeException('OpenRouteService tidak bisa dihubungi: '.$exception->getMessage(), 0, $exception);
        }

        // Counted for the dashboard's API quota; a 429 was refused, not used.
        if ($response->status() !== 429) {
            ApiUsage::record(ApiUsage::OPENROUTESERVICE);
        }

        if ($response->failed()) {
            throw new RuntimeException('OpenRouteService gagal: '.$response->body());
        }

        $route = $response->json('features.0');
        $coordinates = $route['geometry']['coordinates'] ?? [];
        $segments = $route['properties']['segments'] ?? [];
        $wayPoints = $route['properties']['way_points'] ?? [];

        $legs = [];
        foreach ($segments as $segmentIndex => $segment) {
            $from = $wayPoints[$segmentIndex] ?? null;
            $to = $wayPoints[$segmentIndex + 1] ?? null;
            $legCoordinates = $from === null || $to === null ? [] : array_slice($coordinates, $from, $to - $from + 1);

            $legs[] = [
                'duration_seconds' => (int) round($segment['duration'] ?? 0),
                'polyline' => EncodedPolyline::encode(array_map(
                    fn (array $coordinate) => ['lat' => (float) $coordinate[1], 'lng' => (float) $coordinate[0]],
                    $legCoordinates
                )),
            ];
        }

        return $legs;
    }
}
