<?php

namespace App\Services\Places;

use App\Models\Place;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * F022 - "Perkirakan harga" on the admin edit page: Gemini estimates the
 * price of a place from its own knowledge. No web search: Grounding with
 * Google Search has no free tier for this project (Gemini 2.5 is closed to
 * new users, Gemini 3 grounding needs a paid tier), so the answer can be
 * off and the admin decides whether to use it.
 */
class GeminiPriceEstimateClient
{
    private const TIMEOUT_SECONDS = 60;

    /**
     * @return array{text: string, estimated_cost_idr: int|null}
     */
    public function estimate(Place $place): array
    {
        $model = config('services.gemini.model');
        $priceOf = match ($place->type) {
            'lodging' => 'harga kamar standar per malam',
            'culinary' => 'biaya sekali makan per orang',
            default => 'harga tiket masuk per orang (0 kalau gratis)',
        };
        $placeText = implode(', ', array_filter([$place->name, $place->address, $place->kecamatan, 'Batam']));

        $prompt = <<<PROMPT
            Perkirakan {$priceOf} untuk: {$placeText}.
            Balas HANYA dalam format JSON persis seperti ini, tanpa teks lain:
            {
              "estimated_cost_idr": angka bulat dalam Rupiah, atau null kalau kamu tidak punya gambaran sama sekali,
              "explanation": "1-3 kalimat Bahasa Indonesia: kisaran harga dan dasar perkiraanmu. Jujur kalau tidak yakin."
            }
            PROMPT;

        try {
            $response = Http::withHeaders(['x-goog-api-key' => config('services.gemini.api_key')])
                ->timeout(self::TIMEOUT_SECONDS)
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'generationConfig' => ['responseMimeType' => 'application/json'],
                ]);
        } catch (ConnectionException) {
            throw new RuntimeException('Gemini tidak bisa dihubungi, coba lagi.');
        }

        if ($response->status() === 429) {
            throw new RuntimeException('Kuota Gemini sedang habis, coba lagi beberapa saat lagi.');
        }

        if ($response->status() === 404) {
            Log::error('Gemini model not found', ['model' => $model]);

            throw new RuntimeException("Model Gemini \"{$model}\" tidak tersedia. Periksa GEMINI_MODEL di .env.");
        }

        if ($response->failed()) {
            Log::warning('Gemini price estimate failed', ['places_id' => $place->places_id, 'status' => $response->status()]);

            throw new RuntimeException('Perkiraan harga gagal ('.$response->status().'), coba lagi.');
        }

        Log::info('Gemini price estimate', ['places_id' => $place->places_id, 'model' => $model]);

        $parsed = json_decode((string) $response->json('candidates.0.content.parts.0.text'), true);
        if (! is_array($parsed)) {
            throw new RuntimeException('Jawaban Gemini tidak bisa dibaca, coba lagi.');
        }

        return [
            'text' => trim((string) ($parsed['explanation'] ?? '')),
            'estimated_cost_idr' => GeminiEnrichmentClient::cost($parsed['estimated_cost_idr'] ?? null),
        ];
    }
}
