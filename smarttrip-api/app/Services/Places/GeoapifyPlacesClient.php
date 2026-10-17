<?php

namespace App\Services\Places;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * F018/F020 place data from Geoapify (OpenStreetMap based), replacing Google
 * Places on 2026-10-13 because the Google project could not enable billing.
 * Free plan: 3,000 credits a day, no credit card. Places search costs 1
 * credit per 20 results, Place Details 1 credit per call.
 *
 * Geoapify has no ratings and no photos: rating stays null (the backend
 * falls back to PlaceRatingEstimator) and photos come from the admin.
 *
 * Places are keyed by their OpenStreetMap element ("osm:n703856231"), not by
 * Geoapify's place_id: that id embeds the coordinates and the name, so search
 * and details return different ids for the same place, and it changes
 * whenever OSM nudges a node.
 */
class GeoapifyPlacesClient
{
    private const PLACES_URL = 'https://api.geoapify.com/v2/places';

    private const DETAILS_URL = 'https://api.geoapify.com/v2/place-details';

    private const GEOCODE_URL = 'https://api.geoapify.com/v1/geocode/search';

    // Batam, Rempang, Galang and the Belakang Padang and Bulang islands (lon1,lat1,lon2,lat2).
    private const BATAM_RECT = '103.65,0.45,104.45,1.25';

    private const TIMEOUT_SECONDS = 30;

    private const RESULTS_PER_CREDIT = 20;

    /**
     * Named places of [categories] inside a circle.
     *
     * Results that do not come from OpenStreetMap have no stable key and are
     * left out.
     *
     * @return array<int, array{external_place_id: string, name: string, lat: float, lng: float, types: array<int, string>}>
     */
    public function search(float $lat, float $lng, int $radiusMeters, string $categories, int $limit = 20): array
    {
        $response = $this->get(self::PLACES_URL, [
            'categories' => $categories,
            'conditions' => 'named',
            // Geoapify takes lon,lat.
            'filter' => "circle:{$lng},{$lat},{$radiusMeters}",
            'limit' => $limit,
            'lang' => 'id',
        ], 'Geoapify Places');

        $features = $response->json('features', []);
        $this->recordCredits(max(1, (int) ceil(count($features) / self::RESULTS_PER_CREDIT)));

        return collect($features)
            ->map(fn (array $feature) => [
                'external_place_id' => self::externalPlaceId($feature['properties'] ?? []),
                'name' => $feature['properties']['name'] ?? '',
                'lat' => (float) ($feature['properties']['lat'] ?? 0),
                'lng' => (float) ($feature['properties']['lon'] ?? 0),
                'types' => $feature['properties']['categories'] ?? [],
            ])
            ->filter(fn (array $result) => $result['external_place_id'] !== null)
            ->values()
            ->all();
    }

    /**
     * Same shape the approve flow used with Google Place Details, so the
     * candidate review service stays provider agnostic.
     *
     * @return array{
     *     name: string, address: string, lat: float, lng: float, types: array<int, string>,
     *     rating: float|null, review_count: int|null, price_level: string|null,
     *     opening_hours: array|null, description: string|null, phone: string|null,
     *     website: string|null, business_status: string,
     * }
     */
    public function fetch(string $externalPlaceId): array
    {
        if (! preg_match('/^osm:([nwr])(\d+)$/', $externalPlaceId, $osm)) {
            throw new RuntimeException("ID tempat {$externalPlaceId} bukan ID OpenStreetMap, tidak bisa diambil dari Geoapify");
        }

        $response = $this->get(
            self::DETAILS_URL,
            ['osm_type' => $osm[1], 'osm_id' => $osm[2], 'lang' => 'id'],
            'Geoapify Place Details'
        );
        $this->recordCredits(1);

        $details = collect($response->json('features', []))
            ->firstWhere('properties.feature_type', 'details')['properties'] ?? null;

        if ($details === null) {
            throw new RuntimeException('Geoapify Place Details tidak mengembalikan data untuk '.$externalPlaceId);
        }

        $openingHours = $details['opening_hours'] ?? null;

        return [
            'name' => $details['name'] ?? '',
            'address' => $details['formatted'] ?? ($details['address_line2'] ?? ''),
            'lat' => (float) ($details['lat'] ?? 0),
            'lng' => (float) ($details['lon'] ?? 0),
            'types' => $details['categories'] ?? [],
            'rating' => null,
            'review_count' => null,
            'price_level' => null,
            // OSM opening_hours syntax, e.g. "Mo-Su 10:00-22:00".
            'opening_hours' => is_string($openingHours) && $openingHours !== '' ? ['osm' => $openingHours] : null,
            'description' => null,
            'phone' => $details['contact']['phone'] ?? null,
            'website' => $details['website'] ?? null,
            'business_status' => 'operational',
        ];
    }

    /**
     * Free-text address or place search inside Batam, for the admin's manual
     * "Tambah Tempat" form. 1 credit per call.
     *
     * areas lists the result's suburb, district, county and city names so the
     * caller can match one to a kecamatan.
     *
     * @return array<int, array{name: string, address: string, lat: float, lng: float, areas: array<int, string>}>
     */
    public function geocode(string $text, int $limit = 5): array
    {
        $response = $this->get(self::GEOCODE_URL, [
            'text' => $text,
            'filter' => 'rect:'.self::BATAM_RECT,
            'limit' => $limit,
            'lang' => 'id',
            'format' => 'json',
        ], 'Geoapify Geocoding');
        $this->recordCredits(1);

        return collect($response->json('results', []))
            ->map(fn (array $result) => [
                'name' => $result['name'] ?? ($result['address_line1'] ?? ''),
                'address' => $result['formatted'] ?? '',
                'lat' => (float) ($result['lat'] ?? 0),
                'lng' => (float) ($result['lon'] ?? 0),
                'areas' => collect(['suburb', 'district', 'city_district', 'county', 'city'])
                    ->map(fn (string $key) => $result[$key] ?? null)
                    ->filter(fn ($area) => is_string($area) && $area !== '')
                    ->values()
                    ->all(),
            ])
            ->values()
            ->all();
    }

    /**
     * Credits spent today, shown on the admin dashboard (F024). Geoapify
     * resets the free quota daily.
     */
    public static function creditsUsedToday(): int
    {
        return (int) Cache::get(self::creditsKey(), 0);
    }

    private static function externalPlaceId(array $properties): ?string
    {
        $raw = $properties['datasource']['raw'] ?? [];

        return isset($raw['osm_type'], $raw['osm_id']) ? "osm:{$raw['osm_type']}{$raw['osm_id']}" : null;
    }

    private function recordCredits(int $credits): void
    {
        $key = self::creditsKey();
        Cache::add($key, 0, now()->addDays(2));
        Cache::increment($key, $credits);
    }

    private static function creditsKey(): string
    {
        return 'geoapify:credits:'.now()->toDateString();
    }

    private function get(string $url, array $query, string $label): Response
    {
        $apiKey = (string) config('services.geoapify.api_key');

        try {
            $response = Http::timeout(self::TIMEOUT_SECONDS)->get($url, [...$query, 'apiKey' => $apiKey]);
        } catch (ConnectionException $exception) {
            // cURL errors quote the full URL; keep the key out of logs and
            // the admin flash message.
            $message = $apiKey === '' ? $exception->getMessage() : str_replace($apiKey, '***', $exception->getMessage());

            throw new RuntimeException("{$label} tidak bisa dihubungi: {$message}", 0, $exception);
        }

        if ($response->failed()) {
            throw new RuntimeException("{$label} gagal: ".$response->body());
        }

        return $response;
    }
}
