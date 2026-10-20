<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Services\ApiUsage;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * "Perkiraan data dengan AI" on the admin edit page: Gemini reads what
 * GooglePlaceLookupClient found (numbered sources) and proposes the price,
 * the visit length and indoor/outdoor, each with the source numbers it used.
 * A value without a real source, or outside the sensible range for the place
 * type, is dropped. Opening hours are not Gemini's: they are copied from
 * Google Maps as they are.
 */
class GeminiPlaceDataClient
{
    // Kept below what is left of IIS's 70 second FastCGI activity limit after
    // the two SerpApi searches.
    private const TIMEOUT_SECONDS = 40;

    /**
     * @param  array{maps: array|null, web: array<int, array>}  $lookup  from GooglePlaceLookupClient::lookUp()
     * @return array{
     *     fields: array{
     *         estimated_cost_idr: array{value: int|null, note: string|null, sources: array<int, int>},
     *         estimated_visit_minutes: array{value: int|null, note: string|null, sources: array<int, int>},
     *         is_outdoor: array{value: bool|null, note: string|null, sources: array<int, int>},
     *         opening_hours: array{value: array<int, string>|null, note: string|null, sources: array<int, int>},
     *     },
     *     sources: array<int, array{number: int, title: string, link: string, source: string|null, date: string|null}>,
     *     closed: string|null,
     * }
     */
    public function estimate(Place $place, array $lookup): array
    {
        $sources = self::numberedSources($lookup);
        $maps = $lookup['maps'] ?? null;

        $result = [
            'fields' => [
                'estimated_cost_idr' => ['value' => null, 'note' => null, 'sources' => []],
                'estimated_visit_minutes' => ['value' => null, 'note' => null, 'sources' => []],
                'is_outdoor' => ['value' => null, 'note' => null, 'sources' => []],
                // rows: the edit page's seven day rows, filled by "Pakai".
                'opening_hours' => $maps !== null && $maps['hours'] !== []
                    ? ['value' => $maps['hours'], 'note' => 'Disalin apa adanya dari Google Maps.', 'sources' => [1],
                        'rows' => OpeningHours::formRows(OpeningHours::fromLines($maps['hours']))]
                    : ['value' => null, 'note' => 'Google Maps tidak mencantumkan jam buka.', 'sources' => [], 'rows' => null],
            ],
            'sources' => array_map(fn (array $source) => array_intersect_key($source, array_flip(['number', 'title', 'link', 'source', 'date'])), $sources),
            'closed' => $maps['closed'] ?? null,
        ];

        // Nothing to estimate for a place that no longer exists.
        if ($sources === [] || $result['closed'] === 'permanent') {
            return $result;
        }

        $answer = $this->ask($place, $sources);
        $validNumbers = array_column($sources, 'number');

        foreach (['estimated_cost_idr', 'estimated_visit_minutes', 'is_outdoor'] as $field) {
            $item = is_array($answer[$field] ?? null) ? $answer[$field] : [];
            $cited = array_values(array_unique(array_filter(
                is_array($item['sources'] ?? null) ? $item['sources'] : [],
                fn ($number) => is_int($number) && in_array($number, $validNumbers, true),
            )));
            $value = match ($field) {
                'estimated_cost_idr' => GeminiEnrichmentClient::cost($item['value'] ?? null),
                'estimated_visit_minutes' => is_int($item['value'] ?? null) ? $item['value'] : null,
                'is_outdoor' => is_bool($item['value'] ?? null) ? $item['value'] : null,
            };
            $note = is_string($item['note'] ?? null) && trim($item['note']) !== '' ? trim($item['note']) : null;

            if ($value !== null && $cited === []) {
                $value = null;
                $note = 'Tidak ada sumber yang menyebutkannya.';
            }
            if ($field === 'estimated_cost_idr' && $value !== null && ! PlaceEnrichmentService::reasonableCost($place->type, $value)) {
                $value = null;
                $note = 'Angka dari sumber di luar kisaran wajar untuk jenis tempat ini.';
            }
            if ($field === 'estimated_visit_minutes' && $value !== null && ! PlaceEnrichmentService::reasonableVisitMinutes($place->type, $value)) {
                $value = null;
                $note = 'Lama kunjungan di luar kisaran wajar.';
            }

            $result['fields'][$field] = ['value' => $value, 'note' => $note, 'sources' => $value === null ? [] : $cited];
        }

        return $result;
    }

    /**
     * Google Maps first (number 1), then the web results.
     *
     * @return array<int, array{number: int, title: string, link: string, source: string|null, date: string|null, text: string}>
     */
    public static function numberedSources(array $lookup): array
    {
        $sources = [];
        $maps = $lookup['maps'] ?? null;

        if ($maps !== null) {
            $lines = array_filter([
                'Nama di Google Maps: '.$maps['title'],
                $maps['types'] !== [] ? 'Jenis: '.implode(', ', $maps['types']) : null,
                $maps['address'] ? 'Alamat: '.$maps['address'] : null,
                $maps['status'] ? 'Status: '.$maps['status'] : null,
                $maps['price'] ? 'Kisaran harga: '.$maps['price'] : null,
                $maps['hours'] !== [] ? 'Jam buka: '.implode('; ', $maps['hours']) : null,
            ]);
            $sources[] = ['number' => 1, 'title' => $maps['title'].' (Google Maps)', 'link' => $maps['link'], 'source' => 'Google Maps', 'date' => null, 'text' => implode("\n", $lines)];
        }

        foreach ($lookup['web'] ?? [] as $web) {
            $sources[] = [
                'number' => count($sources) + 1,
                'title' => $web['title'],
                'link' => $web['link'],
                'source' => $web['source'],
                'date' => $web['date'],
                'text' => $web['snippet'],
            ];
        }

        return $sources;
    }

    private function ask(Place $place, array $sources): array
    {
        $model = config('services.gemini.model');
        $priceOf = match ($place->type) {
            'lodging' => 'harga kamar standar per malam',
            'culinary' => 'biaya sekali makan per orang',
            default => 'harga tiket masuk per orang (0 kalau gratis)',
        };
        $placeText = implode(', ', array_filter([$place->name, $place->address, $place->kecamatan, 'Batam']));
        $sourceText = implode("\n\n", array_map(
            fn (array $source) => "[{$source['number']}] ".$source['title']
                .($source['source'] ? " ({$source['source']}".($source['date'] ? ", {$source['date']}" : '').')' : '')
                ."\n".$source['text'],
            $sources,
        ));

        $prompt = <<<PROMPT
            Tempat: {$placeText}

            Hasil pencarian Google tentang tempat ini, bernomor:
            {$sourceText}

            Tentukan HANYA dari sumber di atas:
            - estimated_cost_idr: {$priceOf} dalam Rupiah (angka bulat)
            - estimated_visit_minutes: lama kunjungan wajar dalam menit; boleh disimpulkan dari jenis tempat di sumber
            - is_outdoor: true kalau kegiatannya di luar ruangan atau terpengaruh cuaca, false kalau di dalam ruangan

            Aturan:
            - Setiap jawaban wajib menyebut nomor sumber yang dipakai di "sources". Tanpa sumber, isi value dengan null.
            - Abaikan sumber tentang tempat lain yang namanya mirip, dan hati-hati dengan harga dari sumber lama; sebut tahunnya di note.
            - Kalau sumber memberi kisaran, pakai angka yang paling umum dan tulis kisarannya di note.
            - note: 1 kalimat Bahasa Indonesia, dasar jawabanmu.
            PROMPT;

        $field = fn (string $type) => [
            'type' => 'OBJECT',
            'properties' => [
                'value' => ['type' => $type, 'nullable' => true],
                'sources' => ['type' => 'ARRAY', 'items' => ['type' => 'INTEGER']],
                'note' => ['type' => 'STRING', 'nullable' => true],
            ],
            'required' => ['value', 'sources', 'note'],
        ];

        try {
            $response = Http::withHeaders(['x-goog-api-key' => config('services.gemini.api_key')])
                ->timeout(self::TIMEOUT_SECONDS)
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'generationConfig' => [
                        'responseMimeType' => 'application/json',
                        'responseSchema' => [
                            'type' => 'OBJECT',
                            'properties' => [
                                'estimated_cost_idr' => $field('INTEGER'),
                                'estimated_visit_minutes' => $field('INTEGER'),
                                'is_outdoor' => $field('BOOLEAN'),
                            ],
                            'required' => ['estimated_cost_idr', 'estimated_visit_minutes', 'is_outdoor'],
                        ],
                    ],
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
            Log::warning('Gemini place data failed', ['places_id' => $place->places_id, 'status' => $response->status()]);

            throw new RuntimeException('Perkiraan data gagal ('.$response->status().'), coba lagi.');
        }

        $parsed = json_decode((string) $response->json('candidates.0.content.parts.0.text'), true);
        if (! is_array($parsed)) {
            throw new RuntimeException('Jawaban Gemini tidak bisa dibaca, coba lagi.');
        }

        return $parsed;
    }
}
