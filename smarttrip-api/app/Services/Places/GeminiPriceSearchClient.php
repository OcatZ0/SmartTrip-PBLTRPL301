<?php

namespace App\Services\Places;

use App\Models\Place;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * F022 - "Cari harga" on the admin edit page: Gemini with Grounding with
 * Google Search looks up the current price of a place.
 *
 * The Gemini API terms only allow showing a grounded answer, with its Search
 * Suggestions, to the person who asked, and forbid caching or reworking it.
 * So the answer is returned as is to the admin and never stored or parsed;
 * the admin reads it and types the price into the form themselves.
 */
class GeminiPriceSearchClient
{
    private const TIMEOUT_SECONDS = 60;

    /**
     * @return array{text: string, search_suggestions: string|null, sources: array<int, array{title: string, url: string}>}
     */
    public function search(Place $place): array
    {
        $model = config('services.gemini.grounding_model');
        $priceOf = match ($place->type) {
            'lodging' => 'harga kamar standar per malam',
            'culinary' => 'kisaran biaya sekali makan per orang',
            default => 'harga tiket masuk per orang (atau gratis)',
        };
        $placeText = implode(', ', array_filter([$place->name, $place->address, $place->kecamatan, 'Batam']));

        $prompt = "Cari {$priceOf} saat ini untuk: {$placeText}. "
            .'Jawab singkat dalam Bahasa Indonesia, maksimal 4 kalimat: sebut kisaran harga dalam Rupiah, '
            .'dari mana harga itu (misalnya situs pemesanan atau situs resmi), dan kapan datanya kalau ada. '
            .'Kalau tidak menemukan harga untuk tempat ini, katakan tidak menemukan, jangan menebak.';

        try {
            $response = Http::withHeaders(['x-goog-api-key' => config('services.gemini.api_key')])
                ->timeout(self::TIMEOUT_SECONDS)
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'tools' => [['google_search' => (object) []]],
                ]);
        } catch (ConnectionException) {
            throw new RuntimeException('Gemini tidak bisa dihubungi, coba lagi.');
        }

        if ($response->status() === 429) {
            throw new RuntimeException('Kuota pencarian Gemini hari ini sudah habis, coba lagi besok.');
        }

        if ($response->failed()) {
            Log::warning('Gemini price search failed', ['places_id' => $place->places_id, 'status' => $response->status()]);

            throw new RuntimeException('Pencarian harga gagal ('.$response->status().').');
        }

        Log::info('Gemini price search', ['places_id' => $place->places_id, 'model' => $model]);

        $candidate = $response->json('candidates.0', []);
        $text = collect($candidate['content']['parts'] ?? [])->pluck('text')->filter()->implode('');

        return [
            'text' => trim($text),
            'search_suggestions' => $candidate['groundingMetadata']['searchEntryPoint']['renderedContent'] ?? null,
            'sources' => collect($candidate['groundingMetadata']['groundingChunks'] ?? [])
                ->pluck('web')
                ->filter(fn ($web) => is_array($web) && str_starts_with((string) ($web['uri'] ?? ''), 'http'))
                ->map(fn (array $web) => ['title' => (string) ($web['title'] ?? $web['uri']), 'url' => $web['uri']])
                ->values()
                ->all(),
        ];
    }
}
