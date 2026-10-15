<?php

namespace App\Services\Places;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * Google Images results through SerpApi (free plan: 250 searches a month).
 * A search costs one credit however many results it returns, so the same
 * query is cached for a day.
 */
class GoogleImagesClient
{
    private const SEARCH_URL = 'https://serpapi.com/search';

    private const TIMEOUT_SECONDS = 30;

    private const CACHE_SECONDS = 86400;

    public const MAX_RESULTS = 9;

    /**
     * @return array<int, array{title: string, url: string, thumbnail: string|null, source: string|null, source_url: string|null}>
     */
    public function search(string $query): array
    {
        $apiKey = config('services.serpapi.api_key');
        if (empty($apiKey)) {
            throw new RuntimeException('SERPAPI_API_KEY belum diisi di .env.');
        }

        $query = trim($query);

        return Cache::remember('serpapi:images:'.self::MAX_RESULTS.':'.md5(mb_strtolower($query)), self::CACHE_SECONDS, function () use ($query, $apiKey) {
            try {
                $response = Http::timeout(self::TIMEOUT_SECONDS)->get(self::SEARCH_URL, [
                    'engine' => 'google_images',
                    'q' => $query,
                    'gl' => 'id',
                    'hl' => 'id',
                    'api_key' => $apiKey,
                ]);
            } catch (ConnectionException) {
                // Not the exception message: it carries the request URL, api_key included.
                throw new RuntimeException('SerpApi tidak bisa dihubungi, coba lagi.');
            }

            if ($response->status() === 429) {
                throw new RuntimeException('Kuota pencarian SerpApi bulan ini sudah habis.');
            }

            if ($response->failed()) {
                Log::warning('SerpApi search failed', ['status' => $response->status(), 'error' => $response->json('error')]);

                throw new RuntimeException('Pencarian Google Gambar gagal ('.$response->status().').');
            }

            Log::info('SerpApi search', ['query' => $query]);

            return collect($response->json('images_results', []))
                ->filter(fn (array $image) => str_starts_with((string) ($image['original'] ?? ''), 'http'))
                ->take(self::MAX_RESULTS)
                ->map(fn (array $image) => [
                    'title' => (string) ($image['title'] ?? ''),
                    'url' => $image['original'],
                    'thumbnail' => $image['thumbnail'] ?? null,
                    'source' => $image['source'] ?? null,
                    'source_url' => $image['link'] ?? null,
                ])
                ->values()
                ->all();
        });
    }
}
