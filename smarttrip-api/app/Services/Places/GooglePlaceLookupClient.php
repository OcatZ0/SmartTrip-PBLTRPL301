<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Services\Itinerary\Haversine;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * What Google knows about a place, through SerpApi (free plan: 250 searches
 * a month, shared with GoogleImagesClient): the Google Maps entry (type,
 * status, opening hours, price range) and the top web results for its price.
 * Gemini only reads these; it does not search (Search grounding has no free
 * tier for this project).
 *
 * Two searches per place, cached for 30 days. Automatic lookups (candidate
 * approval, places:enrich) only run while more than services.serpapi.reserve
 * searches are left, so the admin's buttons keep working.
 */
class GooglePlaceLookupClient
{
    private const SEARCH_URL = 'https://serpapi.com/search';

    private const ACCOUNT_URL = 'https://serpapi.com/account';

    private const ACCOUNT_CACHE_KEY = 'serpapi:account';

    private const TIMEOUT_SECONDS = 30;

    private const CACHE_SECONDS = 30 * 86400;

    /**
     * A Google Maps result further than this from our coordinates is another place.
     */
    private const MAX_DISTANCE_KM = 1.5;

    private const MAX_WEB_RESULTS = 6;

    private const DAYS = [
        'senin' => 'Senin', 'selasa' => 'Selasa', 'rabu' => 'Rabu', 'kamis' => 'Kamis',
        'jumat' => 'Jumat', 'sabtu' => 'Sabtu', 'minggu' => 'Minggu',
        'monday' => 'Senin', 'tuesday' => 'Selasa', 'wednesday' => 'Rabu', 'thursday' => 'Kamis',
        'friday' => 'Jumat', 'saturday' => 'Sabtu', 'sunday' => 'Minggu',
    ];

    public function isConfigured(): bool
    {
        return filled(config('services.serpapi.api_key'));
    }

    /**
     * Whether an automatic lookup may spend searches now.
     */
    public function canLookUpAutomatically(): bool
    {
        $account = $this->account();

        return $account !== null && $account['searches_left'] > (int) config('services.serpapi.reserve', 50);
    }

    /**
     * The SerpApi plan this month, for the dashboard and the reserve check.
     * The account call is free; it is cached for 10 minutes and refreshed
     * after every search. Null when SerpApi is not set up or not reachable.
     *
     * @return array{searches_per_month: int, searches_left: int, used_this_month: int, renews_on: string|null}|null
     */
    public function account(): ?array
    {
        if (! $this->isConfigured()) {
            return null;
        }

        return Cache::remember(self::ACCOUNT_CACHE_KEY, 600, function () {
            try {
                $response = Http::timeout(8)->get(self::ACCOUNT_URL, ['api_key' => config('services.serpapi.api_key')]);
            } catch (ConnectionException) {
                return null;
            }

            if (! $response->successful()) {
                return null;
            }

            return [
                'searches_per_month' => (int) $response->json('searches_per_month', 0),
                'searches_left' => (int) $response->json('total_searches_left', 0),
                'used_this_month' => (int) $response->json('this_month_usage', 0),
                'renews_on' => is_string($response->json('plan_renewal_date')) ? $response->json('plan_renewal_date') : null,
            ];
        });
    }

    /**
     * @return array{
     *     maps: array{title: string, types: array<int, string>, address: string|null, status: string|null,
     *         closed: string|null, hours: array<int, string>, price: string|null, rating: float|null,
     *         reviews: int|null, distance_km: float|null, link: string}|null,
     *     web: array<int, array{title: string, link: string, source: string|null, date: string|null, snippet: string}>,
     * }
     *
     * @throws RuntimeException when SerpApi is not set up, cannot be reached or is out of searches
     */
    public function lookUp(Place $place): array
    {
        if (! $this->isConfigured()) {
            throw new RuntimeException('SERPAPI_API_KEY belum diisi di .env.');
        }

        $key = 'serpapi:place:'.$place->places_id.':'.md5(mb_strtolower($place->name.'|'.$place->type));

        return Cache::remember($key, self::CACHE_SECONDS, fn () => [
            'maps' => $this->maps($place),
            'web' => $this->web($place),
        ]);
    }

    private function maps(Place $place): ?array
    {
        $query = implode(', ', array_filter([$place->name, $place->kecamatan, 'Batam']));
        $params = ['engine' => 'google_maps', 'type' => 'search', 'q' => $query, 'hl' => 'id', 'gl' => 'id'];
        if ($place->lat !== null && $place->lng !== null) {
            $params['ll'] = '@'.$place->lat.','.$place->lng.',15z';
        }

        $json = $this->search($params)->json();

        // One clear match comes back as place_results, several as local_results.
        $candidates = isset($json['place_results']) ? [$json['place_results']] : ($json['local_results'] ?? []);

        $best = null;
        foreach ($candidates as $result) {
            $distance = $this->distanceKm($place, $result['gps_coordinates'] ?? null);
            if ($distance !== null && $distance > self::MAX_DISTANCE_KM) {
                continue;
            }
            if ($best === null || ($distance ?? INF) < ($best['distance'] ?? INF)) {
                $best = ['result' => $result, 'distance' => $distance];
            }
        }

        if ($best === null) {
            return null;
        }

        $result = $best['result'];
        $status = is_string($result['open_state'] ?? null) ? $result['open_state'] : null;
        $placeId = $result['place_id'] ?? null;

        return [
            'title' => (string) ($result['title'] ?? $place->name),
            'types' => array_values(array_filter((array) ($result['type'] ?? $result['types'] ?? []), 'is_string')),
            'address' => $result['address'] ?? null,
            'status' => $status,
            'closed' => self::closedState($status),
            'hours' => self::hoursLines($result['hours'] ?? $result['operating_hours'] ?? null),
            'price' => is_string($result['price'] ?? null) ? $result['price'] : null,
            'rating' => isset($result['rating']) ? (float) $result['rating'] : null,
            'reviews' => isset($result['reviews']) ? (int) $result['reviews'] : null,
            'distance_km' => $best['distance'] === null ? null : round($best['distance'], 2),
            'link' => $placeId
                ? 'https://www.google.com/maps/place/?q=place_id:'.$placeId
                : 'https://www.google.com/maps/search/'.rawurlencode($query),
        ];
    }

    private function web(Place $place): array
    {
        $query = match ($place->type) {
            'lodging' => "harga kamar {$place->name} Batam per malam",
            'culinary' => "harga menu {$place->name} Batam",
            default => "harga tiket masuk {$place->name} Batam",
        };

        $json = $this->search(['engine' => 'google', 'q' => $query, 'hl' => 'id', 'gl' => 'id', 'num' => 10])->json();

        return collect($json['organic_results'] ?? [])
            ->filter(fn ($result) => is_array($result) && filled($result['snippet'] ?? null) && str_starts_with((string) ($result['link'] ?? ''), 'http'))
            ->take(self::MAX_WEB_RESULTS)
            ->map(fn (array $result) => [
                'title' => trim((string) ($result['title'] ?? '')),
                'link' => $result['link'],
                'source' => is_string($result['source'] ?? null) ? $result['source'] : null,
                'date' => is_string($result['date'] ?? null) ? $result['date'] : null,
                'snippet' => trim((string) $result['snippet']),
            ])
            ->values()
            ->all();
    }

    /**
     * "Permanently closed", "Tutup permanen" and the like, from Google Maps' open_state.
     */
    public static function closedState(?string $status): ?string
    {
        $status = mb_strtolower((string) $status);

        return match (true) {
            str_contains($status, 'permanen'), str_contains($status, 'permanently') => 'permanent',
            str_contains($status, 'sementara'), str_contains($status, 'temporarily') => 'temporary',
            default => null,
        };
    }

    /**
     * [{"senin": "11.00–23.00"}, ...] or {"monday": "9 AM–6 PM"} into "Senin: 11.00–23.00" lines, Monday first.
     *
     * @return array<int, string>
     */
    public static function hoursLines(mixed $hours): array
    {
        if (! is_array($hours)) {
            return [];
        }

        $byDay = [];
        $entries = array_is_list($hours) ? $hours : [$hours];
        foreach ($entries as $entry) {
            foreach ((array) $entry as $day => $time) {
                $name = self::DAYS[mb_strtolower(trim((string) $day))] ?? null;
                if ($name !== null && is_string($time) && trim($time) !== '') {
                    $byDay[$name] = trim($time);
                }
            }
        }

        $lines = [];
        foreach (array_unique(array_values(self::DAYS)) as $day) {
            if (isset($byDay[$day])) {
                $lines[] = "{$day}: {$byDay[$day]}";
            }
        }

        return $lines;
    }

    private function distanceKm(Place $place, mixed $gps): ?float
    {
        if ($place->lat === null || $place->lng === null || ! is_array($gps) || ! isset($gps['latitude'], $gps['longitude'])) {
            return null;
        }

        return Haversine::km((float) $place->lat, (float) $place->lng, (float) $gps['latitude'], (float) $gps['longitude']);
    }

    private function search(array $params): Response
    {
        try {
            $response = Http::timeout(self::TIMEOUT_SECONDS)->get(self::SEARCH_URL, [
                ...$params,
                'api_key' => config('services.serpapi.api_key'),
            ]);
        } catch (ConnectionException) {
            // Not the exception message: it carries the request URL, api_key included.
            throw new RuntimeException('SerpApi tidak bisa dihubungi, coba lagi.');
        }

        if ($response->status() === 429) {
            throw new RuntimeException('Kuota pencarian SerpApi bulan ini sudah habis.');
        }

        if ($response->failed()) {
            Log::warning('SerpApi lookup failed', ['engine' => $params['engine'], 'status' => $response->status(), 'error' => $response->json('error')]);

            throw new RuntimeException('Pencarian Google lewat SerpApi gagal ('.$response->status().').');
        }

        Log::info('SerpApi lookup', ['engine' => $params['engine'], 'q' => $params['q']]);
        Cache::forget(self::ACCOUNT_CACHE_KEY);

        return $response;
    }
}
