<?php

namespace App\Services\Places;

use App\Services\ApiUsage;
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
 * menandainya untuk direview admin. Sejak 2026-10-15 juga perkiraan biaya
 * (estimated_cost_idr) dari pengetahuan model, tanpa pencarian web; hanya
 * mengisi biaya yang masih kosong, admin bisa mengubahnya kapan saja.
 *
 * Sejak 2026-10-17 jawabannya dikunci responseSchema dan Gemini diberi fakta
 * dari sumber data (kategori dan tag OpenStreetMap, jam buka) supaya
 * deskripsi ditulis dari fakta, bukan dikarang; kalau Gemini tidak mengenal
 * tempatnya ia boleh menjawab null (description_confidence "rendah").
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
     * How sure Gemini is about a description it wrote itself; "rendah" means
     * it does not really know the place, and the description is not kept.
     */
    public const CONFIDENCE_LEVELS = ['tinggi', 'sedang', 'rendah'];

    /**
     * @param  array<string, string>  $availableCategories  categories yang sudah di-seed (Section 3: wajib diseed duluan), slug => name_id; the name tells Gemini what each tag means
     * @param  array{type?: string|null, kecamatan?: string|null, address?: string|null}  $context  helps Gemini tell same-named places apart
     * @param  array<int, string>  $facts  what the data sources say about the place ("Kategori OpenStreetMap: beach"); the only ground Gemini may describe from
     * @return array{description_id: string|null, description_confidence: string|null, description_en: string|null, category_tags: array<int, string>, estimated_visit_minutes: int|null, is_outdoor: bool|null, estimated_cost_idr: int|null, search_keywords: array<int, string>}
     */
    public function enrich(string $name, ?string $descriptionId, array $availableCategories, array $context = [], array $facts = []): array
    {
        $model = config('services.gemini.model');
        $availableCategorySlugs = array_keys($availableCategories);
        // "- pantai (Pantai)": a bare slug like "spot-foto" is easy to misread.
        $categoryList = implode("\n", array_map(
            fn (string $slug, string $categoryName) => "- {$slug} ({$categoryName})",
            $availableCategorySlugs,
            $availableCategories,
        ));
        $hasDescription = trim((string) $descriptionId) !== '';
        $place = implode(', ', array_filter([
            $name,
            $context['type'] ?? null,
            $context['kecamatan'] ?? null,
            $context['address'] ?? null,
        ]));
        $factList = $facts === []
            ? '- (tidak ada fakta tambahan dari sumber data)'
            : implode("\n", array_map(fn (string $fact) => "- {$fact}", $facts));

        $descriptionTask = $hasDescription
            ? "Deskripsi (Bahasa Indonesia): {$descriptionId}\n"
                .'Deskripsi sudah ada: isi description_id dan description_confidence dengan null.'
            : "Tempat ini belum punya deskripsi. Tulis deskripsi singkat 2-3 kalimat Bahasa Indonesia yang hidup dan mengajak wisatawan,\n"
                ."HANYA dari fakta di atas dan hal yang pasti benar untuk jenis tempat seperti ini (pantai: angin laut dan pasir; restoran seafood: hidangan laut).\n"
                ."Dilarang menyebut harga, jam buka, nomor telepon, fasilitas, menu, atau pemandangan yang tidak ada di fakta.\n"
                .'Gaya: '.self::descriptionAngle($name)."\n"
                ."Jangan membuka dengan \"{$name} adalah\" dan jangan pakai frasa \"yang terletak di kawasan\"; sebut lokasinya cukup sekali dan singkat.\n"
                ."Variasikan struktur kalimat; hindari kata klise seperti \"menawarkan\", \"destinasi\", dan \"merupakan\".\n"
                ."Nilai keyakinanmu di description_confidence:\n"
                ."- tinggi: fakta cukup, atau kamu benar-benar mengenal tempat ini\n"
                ."- sedang: deskripsi bersifat umum sesuai jenis tempatnya, tanpa klaim khusus\n"
                .'- rendah: kamu tidak mengenal tempat ini dan fakta tidak cukup; isi description_id dengan null';

        $costMeaning = match ($context['type'] ?? null) {
            'lodging' => 'harga kamar standar per malam',
            'culinary' => 'biaya sekali makan per orang',
            default => 'harga tiket masuk per orang, 0 kalau gratis',
        };

        $prompt = <<<PROMPT
            Kamu membantu kurasi data tempat wisata/kuliner/hotel di Batam, Indonesia.
            Tempat: {$place}

            Fakta dari sumber data (OpenStreetMap/Geoapify), anggap benar:
            {$factList}

            {$descriptionTask}

            Daftar tag kategori yang TERSEDIA, format "slug (nama)". Cuma boleh pilih slug dari daftar ini:
            {$categoryList}

            Isi field lain:
            - description_en: terjemahan Inggris dari deskripsi Bahasa Indonesia (yang sudah ada atau yang kamu tulis); null kalau tidak ada deskripsi
            - category_tags: slug yang cocok dari daftar, boleh kosong
            - estimated_visit_minutes: lama kunjungan wajar dalam menit, null kalau tidak tahu
            - is_outdoor: apakah tempat ini sensitif cuaca/kegiatan luar ruangan, null kalau tidak tahu
            - estimated_cost_idr: angka bulat perkiraan {$costMeaning} dalam Rupiah, null kalau kamu tidak punya gambaran
            - search_keywords: 6 sampai 10 kata kunci pencarian singkat (1-3 kata) yang akan diketik wisatawan: kegiatan, suasana, makanan, atau ciri khasnya; jangan ulangi nama tempat dan jangan mengarang

            Lebih baik null daripada menebak.
            PROMPT;

        try {
            $response = Http::withHeaders([
                'Content-Type' => 'application/json',
                'x-goog-api-key' => config('services.gemini.api_key'),
            ])
                ->timeout(self::TIMEOUT_SECONDS)
                ->retry(self::RETRY_TIMES, self::RETRY_SLEEP_MS, fn ($exception) => $exception instanceof ConnectionException
                    || ($exception instanceof RequestException && in_array($exception->response->status(), self::RETRYABLE_STATUSES, true)), throw: false)
                ->post("https://generativelanguage.googleapis.com/v1beta/models/{$model}:generateContent", [
                    'contents' => [['parts' => [['text' => $prompt]]]],
                    'generationConfig' => [
                        'responseMimeType' => 'application/json',
                        'responseSchema' => self::responseSchema($availableCategorySlugs),
                    ],
                ]);
        } catch (ConnectionException $exception) {
            // Callers only expect RuntimeException (PlaceCandidateReviewService
            // keeps the place promoted without enrichment).
            throw new RuntimeException('Gemini API tidak bisa dihubungi: '.$exception->getMessage(), 0, $exception);
        }

        // Counted for the dashboard's API quota; a 429 was refused, not used.
        if ($response->status() !== 429) {
            ApiUsage::record(ApiUsage::GEMINI);
        }

        if ($response->failed()) {
            throw new RuntimeException('Gemini API gagal: '.$response->body());
        }

        $text = $response->json('candidates.0.content.parts.0.text');
        $parsed = json_decode((string) $text, true);

        if (! is_array($parsed)) {
            throw new RuntimeException('Gemini API mengembalikan respons yang tidak bisa di-parse sebagai JSON: '.$text);
        }

        // The schema fixes the types on Google's side; every field is still
        // checked here, since a model can ignore or break it.
        $confidence = in_array($parsed['description_confidence'] ?? null, self::CONFIDENCE_LEVELS, true)
            ? $parsed['description_confidence']
            : null;
        $written = $hasDescription ? null : self::text($parsed['description_id'] ?? null);

        return [
            'description_id' => $written,
            'description_confidence' => $written === null ? null : $confidence,
            'description_en' => self::text($parsed['description_en'] ?? null),
            // Whitelist ketat - Gemini cuma "menyarankan", tag di luar daftar
            // categories yang ada dibuang, bukan ikut kesimpan (Section 5:
            // category_tags langsung dipakai TOPSIS, tidak boleh nyasar).
            'category_tags' => is_array($parsed['category_tags'] ?? null)
                ? array_values(array_intersect($parsed['category_tags'], $availableCategorySlugs))
                : [],
            'estimated_visit_minutes' => self::wholeNumber($parsed['estimated_visit_minutes'] ?? null),
            'is_outdoor' => self::flag($parsed['is_outdoor'] ?? null),
            'estimated_cost_idr' => self::cost($parsed['estimated_cost_idr'] ?? null),
            'search_keywords' => is_array($parsed['search_keywords'] ?? null)
                ? GeminiKeywordSuggestionClient::clean($parsed['search_keywords'])
                : [],
        ];
    }

    /**
     * Where a written description starts, so the catalog does not read as
     * one template. Picked from the name: the same place keeps its angle.
     */
    private const DESCRIPTION_ANGLES = [
        'mulai dari hal yang bisa dilakukan pengunjung di sana.',
        'mulai dari suasana yang akan dirasakan pengunjung.',
        'mulai dari siapa yang paling menikmati tempat ini (keluarga, pasangan, rombongan, pencinta kuliner, dan sebagainya).',
        'mulai dari ciri paling khas tempat ini menurut fakta di atas.',
        'mulai dengan kalimat ajakan singkat, lalu jelaskan tempatnya.',
    ];

    public static function descriptionAngle(string $name): string
    {
        return self::DESCRIPTION_ANGLES[crc32(mb_strtolower($name)) % count(self::DESCRIPTION_ANGLES)];
    }

    /**
     * Gemini's structured output (OpenAPI subset): every field present, with
     * its type, and category tags limited to the seeded slugs.
     *
     * @param  array<int, string>  $categorySlugs
     */
    public static function responseSchema(array $categorySlugs): array
    {
        $tag = ['type' => 'STRING'];
        if ($categorySlugs !== []) {
            $tag['enum'] = array_values($categorySlugs);
        }

        $properties = [
            'description_id' => ['type' => 'STRING', 'nullable' => true],
            'description_confidence' => ['type' => 'STRING', 'enum' => self::CONFIDENCE_LEVELS, 'nullable' => true],
            'description_en' => ['type' => 'STRING', 'nullable' => true],
            'category_tags' => ['type' => 'ARRAY', 'items' => $tag],
            'estimated_visit_minutes' => ['type' => 'INTEGER', 'nullable' => true],
            'is_outdoor' => ['type' => 'BOOLEAN', 'nullable' => true],
            'estimated_cost_idr' => ['type' => 'INTEGER', 'nullable' => true],
            'search_keywords' => ['type' => 'ARRAY', 'items' => ['type' => 'STRING']],
        ];

        return [
            'type' => 'OBJECT',
            'properties' => $properties,
            'required' => array_keys($properties),
            'propertyOrdering' => array_keys($properties),
        ];
    }

    /**
     * Anything outside 0 to Rp 50 juta is a misread, not a price.
     */
    public static function cost(mixed $value): ?int
    {
        if (! is_numeric($value) || $value < 0 || $value > 50_000_000) {
            return null;
        }

        return (int) round($value);
    }

    /**
     * Non-empty text only; an array or a number in a text field is dropped.
     */
    private static function text(mixed $value): ?string
    {
        if (! is_string($value)) {
            return null;
        }

        $value = trim($value);

        return $value === '' ? null : $value;
    }

    /**
     * A real boolean, or the strings "true"/"false". (bool) "false" would be
     * true in PHP.
     */
    private static function flag(mixed $value): ?bool
    {
        if (is_bool($value)) {
            return $value;
        }

        return match (is_string($value) ? strtolower(trim($value)) : null) {
            'true' => true,
            'false' => false,
            default => null,
        };
    }

    /**
     * A positive whole number (90 or "90"); "1,5 jam" and fractions are dropped.
     */
    private static function wholeNumber(mixed $value): ?int
    {
        if (is_int($value) || (is_string($value) && ctype_digit(trim($value)))) {
            $number = (int) $value;

            return $number > 0 ? $number : null;
        }

        if (is_float($value) && $value > 0 && floor($value) === $value) {
            return (int) $value;
        }

        return null;
    }
}
