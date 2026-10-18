<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Services\ApiUsage;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * "Sarankan dengan AI" on the admin Edit Tempat page: Gemini proposes search
 * keywords for one place (places.search_keywords). The admin edits the list
 * before saving; the catalog search then also finds the place by them.
 */
class GeminiKeywordSuggestionClient
{
    private const TIMEOUT_SECONDS = 60;

    private const MAX_KEYWORDS = 12;

    /**
     * @return array<int, string>
     */
    public function suggest(Place $place): array
    {
        $model = config('services.gemini.model');
        $type = match ($place->type) { 'culinary' => 'tempat makan', 'lodging' => 'penginapan', default => 'tempat wisata' };
        $placeText = implode(', ', array_filter([$place->name, $place->kecamatan, 'Batam']));
        $categories = $place->categories->pluck('name_id')->join(', ');
        $description = trim((string) ($place->description_override ?: $place->description_id));

        $context = implode("\n", array_filter([
            $categories !== '' ? "Kategori: {$categories}." : null,
            $description !== '' ? "Deskripsi: {$description}" : null,
        ]));

        $prompt = <<<PROMPT
            Kamu membantu admin aplikasi wisata Batam, Indonesia. Untuk {$type} "{$placeText}",
            tulis 6 sampai 10 kata kunci pencarian singkat (1-3 kata, Bahasa Indonesia, boleh istilah Inggris
            yang umum dipakai wisatawan) yang akan diketik wisatawan untuk menemukan tempat ini: kegiatan,
            suasana, makanan, atau ciri khasnya.
            {$context}
            Jangan ulangi nama tempatnya sendiri dan jangan mengarang hal yang tidak pasti ada di tempat ini.
            Balas HANYA JSON persis seperti ini, tanpa teks lain:
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

        // Counted for the dashboard's API quota; a 429 was refused, not used.
        if ($response->status() !== 429) {
            ApiUsage::record(ApiUsage::GEMINI);
        }

        if ($response->status() === 429) {
            throw new RuntimeException('Kuota Gemini sedang habis, coba lagi beberapa saat lagi.');
        }

        if ($response->failed()) {
            Log::warning('Gemini keyword suggestion failed', ['places_id' => $place->places_id, 'status' => $response->status()]);

            throw new RuntimeException('Saran kata kunci gagal ('.$response->status().'), coba lagi.');
        }

        $parsed = json_decode((string) $response->json('candidates.0.content.parts.0.text'), true);
        if (! is_array($parsed) || ! is_array($parsed['keywords'] ?? null)) {
            throw new RuntimeException('Jawaban Gemini tidak bisa dibaca, coba lagi.');
        }

        return self::clean($parsed['keywords']);
    }

    /**
     * Plain short strings only (a comma would split one keyword into two),
     * at most MAX_KEYWORDS. Also used for the keywords enrichment writes.
     *
     * @return array<int, string>
     */
    public static function clean(array $keywords): array
    {
        $keywords = array_filter(array_map(
            fn ($keyword) => is_string($keyword) ? trim(str_replace(',', ' ', $keyword)) : '',
            $keywords,
        ), fn (string $keyword) => $keyword !== '' && mb_strlen($keyword) <= 40);

        return array_slice(array_values(array_unique($keywords)), 0, self::MAX_KEYWORDS);
    }
}
