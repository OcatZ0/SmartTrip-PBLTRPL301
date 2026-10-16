<?php

namespace App\Services\Places;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * "Sarankan dengan AI" in the admin category popup: Gemini proposes search
 * keywords for a category (categories.search_keywords). The admin edits the
 * list before saving; the keywords then feed the catalog search and the
 * category list Gemini tags places with (GeminiEnrichmentClient).
 */
class GeminiKeywordSuggestionClient
{
    private const TIMEOUT_SECONDS = 60;

    private const MAX_KEYWORDS = 12;

    /**
     * @param  array<int, string>  $samplePlaces  a few places already in the category, as context
     * @return array<int, string>
     */
    public function suggest(string $nameId, ?string $nameEn, array $samplePlaces = []): array
    {
        $model = config('services.gemini.model');
        $category = trim($nameId.($nameEn ? " ({$nameEn})" : ''));
        $examples = $samplePlaces === []
            ? ''
            : 'Contoh tempat di kategori ini: '.implode(', ', $samplePlaces).'.';

        $prompt = <<<PROMPT
            Kamu membantu admin aplikasi wisata Batam, Indonesia. Untuk kategori minat wisata "{$category}",
            tulis 6 sampai 10 kata kunci pencarian singkat (1-3 kata, Bahasa Indonesia, boleh istilah Inggris
            yang umum dipakai wisatawan) yang akan dicari wisatawan untuk menemukan tempat di kategori ini.
            {$examples}
            Jangan ulangi nama kategorinya sendiri. Balas HANYA JSON persis seperti ini, tanpa teks lain:
            {"keywords": ["kata kunci 1", "kata kunci 2"]}
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

        if ($response->failed()) {
            Log::warning('Gemini keyword suggestion failed', ['category' => $nameId, 'status' => $response->status()]);

            throw new RuntimeException('Saran kata kunci gagal ('.$response->status().'), coba lagi.');
        }

        $parsed = json_decode((string) $response->json('candidates.0.content.parts.0.text'), true);
        if (! is_array($parsed) || ! is_array($parsed['keywords'] ?? null)) {
            throw new RuntimeException('Jawaban Gemini tidak bisa dibaca, coba lagi.');
        }

        // Plain short strings only; commas would split one keyword into two.
        $keywords = array_filter(array_map(
            fn ($keyword) => is_string($keyword) ? trim(str_replace(',', ' ', $keyword)) : '',
            $parsed['keywords'],
        ), fn (string $keyword) => $keyword !== '' && mb_strlen($keyword) <= 40);

        return array_slice(array_values(array_unique($keywords)), 0, self::MAX_KEYWORDS);
    }
}
