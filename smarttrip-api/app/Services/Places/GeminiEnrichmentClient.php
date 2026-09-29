<?php

namespace App\Services\Places;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * F019/F020 (docs/prd design spec Section 3 fase 4 - Tagging, Section 5).
 * Satu call Gemini langsung nyambung ke akhir Enrichment (fase 3), begitu
 * description tersimpan dari Place Details - hasilnya description_en
 * (auto-translate), category_tags (disarankan dari categories yang ada),
 * estimated_visit_minutes, dan is_outdoor.
 */
class GeminiEnrichmentClient
{
    /**
     * @param  array<int, string>  $availableCategorySlugs  categories.slug yang sudah di-seed (Section 3: wajib diseed duluan)
     * @return array{description_en: string|null, category_tags: array<int, string>, estimated_visit_minutes: int|null, is_outdoor: bool|null}
     */
    public function enrich(string $name, ?string $descriptionId, array $availableCategorySlugs): array
    {
        $model = config('services.gemini.model', 'gemini-2.0-flash');
        $slugList = implode(', ', $availableCategorySlugs);

        $prompt = <<<PROMPT
            Kamu membantu kurasi data tempat wisata/kuliner/hotel di Batam, Indonesia.
            Nama tempat: {$name}
            Deskripsi (Bahasa Indonesia): {$descriptionId}

            Daftar tag kategori yang TERSEDIA (cuma boleh pilih dari daftar ini, jangan buat tag baru): {$slugList}

            Balas HANYA dalam format JSON persis seperti ini, tanpa teks lain:
            {
              "description_en": "terjemahan Inggris dari deskripsi (null kalau deskripsi kosong)",
              "category_tags": ["slug1", "slug2"],
              "estimated_visit_minutes": angka perkiraan lama kunjungan wajar dalam menit,
              "is_outdoor": true atau false, apakah tempat ini sensitif cuaca/kegiatan luar ruangan
            }
            PROMPT;

        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
            'x-goog-api-key' => config('services.gemini.api_key'),
        ])->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
            'contents' => [['parts' => [['text' => $prompt]]]],
            'generationConfig' => ['responseMimeType' => 'application/json'],
        ]);

        if ($response->failed()) {
            throw new RuntimeException('Gemini API gagal: '.$response->body());
        }

        $text = $response->json('candidates.0.content.parts.0.text');
        $parsed = json_decode((string) $text, true);

        if (! is_array($parsed)) {
            throw new RuntimeException('Gemini API mengembalikan respons yang tidak bisa di-parse sebagai JSON: '.$text);
        }

        return [
            'description_en' => $parsed['description_en'] ?? null,
            // Whitelist ketat - Gemini cuma "menyarankan", tag di luar daftar
            // categories yang ada dibuang, bukan ikut kesimpan (Section 5:
            // category_tags langsung dipakai TOPSIS, tidak boleh nyasar).
            'category_tags' => array_values(array_intersect($parsed['category_tags'] ?? [], $availableCategorySlugs)),
            'estimated_visit_minutes' => isset($parsed['estimated_visit_minutes']) ? (int) $parsed['estimated_visit_minutes'] : null,
            'is_outdoor' => isset($parsed['is_outdoor']) ? (bool) $parsed['is_outdoor'] : null,
        ];
    }
}
