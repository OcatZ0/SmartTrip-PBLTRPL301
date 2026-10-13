<?php

namespace App\Services\Places;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * F019/F020 (docs/prd design spec Section 3 fase 4 - Tagging, Section 5).
 * Satu call Gemini langsung nyambung ke akhir Enrichment (fase 3), begitu
 * description tersimpan dari Place Details - hasilnya description_en
 * (auto-translate), category_tags (disarankan dari categories yang ada),
 * estimated_visit_minutes, dan is_outdoor. Sejak 2026-10-13 juga menulis
 * deskripsi singkat Bahasa Indonesia kalau sumber data tidak punya (Geoapify
 * dan tempat seed memang kosong); teks itu buatan AI, jadi pemanggil
 * menandainya untuk direview admin.
 */
class GeminiEnrichmentClient
{
    /**
     * Flash models regularly answer 503 "high demand" or stall for a while;
     * those are worth a couple of retries before giving up.
     */
    private const RETRY_TIMES = 3;

    private const RETRY_SLEEP_MS = 2000;

    private const TIMEOUT_SECONDS = 60;

    private const RETRYABLE_STATUSES = [429, 500, 503];

    /**
     * @param  array<int, string>  $availableCategorySlugs  categories.slug yang sudah di-seed (Section 3: wajib diseed duluan)
     * @param  array{type?: string|null, kecamatan?: string|null, address?: string|null}  $context  helps Gemini tell same-named places apart
     * @return array{description_id: string|null, description_en: string|null, category_tags: array<int, string>, estimated_visit_minutes: int|null, is_outdoor: bool|null}
     */
    public function enrich(string $name, ?string $descriptionId, array $availableCategorySlugs, array $context = []): array
    {
        $model = config('services.gemini.model');
        $slugList = implode(', ', $availableCategorySlugs);
        $hasDescription = trim((string) $descriptionId) !== '';
        $place = implode(', ', array_filter([
            $name,
            $context['type'] ?? null,
            $context['kecamatan'] ?? null,
            $context['address'] ?? null,
        ]));

        $descriptionTask = $hasDescription
            ? "Deskripsi (Bahasa Indonesia): {$descriptionId}"
            : 'Tempat ini belum punya deskripsi. Tulis deskripsi singkat 2-3 kalimat Bahasa Indonesia yang netral '
                .'tentang tempat ini untuk wisatawan. Hanya tulis hal yang umum diketahui; jangan mengarang harga, '
                .'jam buka, nomor telepon, atau fasilitas yang tidak pasti. Kalau tidak yakin tempat persisnya, '
                .'deskripsikan secara umum sesuai jenis tempatnya.';

        $descriptionIdField = $hasDescription
            ? '"description_id": null,'
            : '"description_id": "deskripsi singkat Bahasa Indonesia yang kamu tulis",';

        $prompt = <<<PROMPT
            Kamu membantu kurasi data tempat wisata/kuliner/hotel di Batam, Indonesia.
            Tempat: {$place}
            {$descriptionTask}

            Daftar tag kategori yang TERSEDIA (cuma boleh pilih dari daftar ini, jangan buat tag baru): {$slugList}

            Balas HANYA dalam format JSON persis seperti ini, tanpa teks lain:
            {
              {$descriptionIdField}
              "description_en": "terjemahan Inggris dari deskripsi Bahasa Indonesia di atas",
              "category_tags": ["slug1", "slug2"],
              "estimated_visit_minutes": angka perkiraan lama kunjungan wajar dalam menit,
              "is_outdoor": true atau false, apakah tempat ini sensitif cuaca/kegiatan luar ruangan
            }
            PROMPT;

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
                'x-goog-api-key' => config('services.gemini.api_key'),
            ])
                ->timeout(self::TIMEOUT_SECONDS)
                ->retry(self::RETRY_TIMES, self::RETRY_SLEEP_MS, fn ($e) => $e instanceof ConnectionException
                    || ($e instanceof RequestException && in_array($e->response->status(), self::RETRYABLE_STATUSES, true)), throw: false)
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'generationConfig' => ['responseMimeType' => 'application/json'],
                ]);
        } catch (ConnectionException $e) {
            // Callers only expect RuntimeException (PlaceCandidateReviewService
            // keeps the place promoted without enrichment).
            throw new RuntimeException('Gemini API tidak bisa dihubungi: '.$e->getMessage(), 0, $e);
        }

        if ($response->failed()) {
            throw new RuntimeException('Gemini API gagal: '.$response->body());
        }

        $text = $response->json('candidates.0.content.parts.0.text');
        $parsed = json_decode((string) $text, true);

        if (! is_array($parsed)) {
            throw new RuntimeException('Gemini API mengembalikan respons yang tidak bisa di-parse sebagai JSON: '.$text);
        }

        $written = $hasDescription ? null : trim((string) ($parsed['description_id'] ?? ''));

        return [
            'description_id' => $written === '' ? null : $written,
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
