<?php

namespace App\Services\Places;

use App\Models\Category;
use App\Models\Place;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * F020: fills a place's gaps from one Gemini call (docs/prd design spec
 * Section 5). Used right after a candidate is approved and by
 * `php artisan places:enrich` for places already in the catalog.
 *
 * Only empty fields are written: an admin's description_override and
 * anything the admin already confirmed (category_tags_reviewed) are left
 * alone. Whatever Gemini writes puts the place back on the dashboard's
 * "needs attention" list, because an AI description can be wrong. A cost
 * guessed by Gemini is only written when the admin left it empty; it is not
 * marked as AI (an estimate the admin keeps is their decision).
 *
 * Against made-up answers (since 2026-10-17): Gemini gets the facts the data
 * sources hold, may answer null, and every answer is checked against those
 * facts and the place type before it is kept (see plausible()). While the
 * SerpApi quota allows, the facts include Google Maps (type, status, hours)
 * and web results for the price, and empty opening hours are copied from
 * Google Maps.
 */
class PlaceEnrichmentService
{
    /**
     * A sensible visit, in minutes, per type; lodging gets none.
     */
    private const VISIT_MINUTES_RANGE = [
        'attraction' => [15, 480],
        'culinary' => [15, 180],
    ];

    /**
     * A sensible price in Rupiah per type: a ticket (0 is free), one meal, one night.
     */
    private const COST_RANGE = [
        'attraction' => [0, 2_000_000],
        'culinary' => [5_000, 1_500_000],
        'lodging' => [50_000, 20_000_000],
    ];

    /**
     * Geoapify category prefixes that settle is_outdoor whatever Gemini says.
     */
    private const OUTDOOR_CATEGORIES = ['beach', 'natural', 'leisure.park', 'national_park', 'camping', 'tourism.attraction.viewpoint', 'leisure.picnic'];

    private const INDOOR_CATEGORIES = ['commercial.shopping_mall', 'entertainment.museum', 'entertainment.cinema', 'entertainment.culture.theatre'];

    public function __construct(
        private readonly GeminiEnrichmentClient $gemini,
        private readonly GeoapifyPlacesClient $geoapify,
        private readonly GooglePlaceLookupClient $google,
    ) {}

    public static function reasonableCost(?string $type, int $cost): bool
    {
        [$min, $max] = self::COST_RANGE[$type] ?? [0, 50_000_000];

        return $cost >= $min && $cost <= $max;
    }

    public static function reasonableVisitMinutes(?string $type, int $minutes): bool
    {
        [$min, $max] = self::VISIT_MINUTES_RANGE[$type] ?? [15, 480];

        return $minutes >= $min && $minutes <= $max;
    }

    /**
     * Whether a call to Gemini could still fill something on [place].
     */
    public function needsEnrichment(Place $place): bool
    {
        if ($this->sourceDescription($place) === null || blank($place->description_en) || $place->estimated_cost_idr === null
            || blank($place->search_keywords)) {
            return true;
        }

        if ($place->category_tags_reviewed) {
            return false;
        }

        if ($place->is_outdoor === null) {
            return true;
        }

        // Hotels never get a visit length or interest categories, so those
        // gaps are not worth a Gemini call.
        return ! $this->isLodging($place)
            && ($place->estimated_visit_minutes === null || ! $place->categories()->exists());
    }

    /**
     * @param  array<string, string>|null  $osmTags  from a Geoapify fetch the caller already made; null looks them up
     * @return array<int, string> the fields that were filled, empty when
     *                            Gemini had nothing new
     *
     * @throws RuntimeException when Gemini cannot be reached or answers
     *                          something unusable
     */
    public function enrich(Place $place, ?array $osmTags = null): array
    {
        $plan = $this->plan($place, $osmTags);

        foreach ($plan['notes'] as $note) {
            Log::info("Enrichment place {$place->places_id}: {$note}");
        }

        if ($plan['category_ids'] !== null) {
            $place->categories()->sync($plan['category_ids']);
        }

        if ($plan['updates'] !== []) {
            $place->update($plan['updates']);
        }

        return $plan['filled'];
    }

    /**
     * What enrich() would write, without writing it (places:enrich --dry-run).
     *
     * @param  array<string, string>|null  $osmTags
     * @return array{facts: array<int, string>, answer: array, notes: array<int, string>, updates: array<string, mixed>, category_ids: array<int, int>|null, filled: array<int, string>}
     */
    public function plan(Place $place, ?array $osmTags = null): array
    {
        $availableCategories = Category::query()->pluck('name_id', 'slug')->all();
        $description = $this->sourceDescription($place);
        $google = $this->lookUpGoogle($place);
        $mapsHours = $google['maps']['hours'] ?? [];
        $facts = [...$this->facts($place, $osmTags ?? $this->lookUpOsmTags($place)), ...$this->googleFacts($google)];

        $answer = $this->gemini->enrich($place->name, $description, $availableCategories, [
            'type' => $place->type,
            'kecamatan' => $place->kecamatan,
            'address' => $place->address,
        ], $facts);

        [$result, $notes] = $this->plausible($place, $answer, $description !== null, $mapsHours !== []);

        if (($google['maps']['closed'] ?? null) === 'permanent') {
            $notes[] = 'Google Maps mencatat tempat ini TUTUP PERMANEN, periksa sebelum ditampilkan';
        }

        $updates = [];

        if ($description === null && $result['description_id'] !== null) {
            $updates['description'] = $result['description_id'];
        }

        if (blank($place->description_en) && filled($result['description_en'])) {
            $updates['description_en'] = $result['description_en'];
        }

        // Confirmed by an admin: keep their tags, duration and outdoor flag.
        $categoryIds = null;
        if (! $place->category_tags_reviewed) {
            if ($place->estimated_visit_minutes === null && $result['estimated_visit_minutes'] !== null && ! $this->isLodging($place)) {
                $updates['estimated_visit_minutes'] = $result['estimated_visit_minutes'];
            }

            if ($place->is_outdoor === null && $result['is_outdoor'] !== null) {
                $updates['is_outdoor'] = $result['is_outdoor'];
            }

            // Interest categories drive TOPSIS for attractions and food;
            // hotels are picked separately in step C4.
            if ($result['category_tags'] !== [] && ! $this->isLodging($place) && ! $place->categories()->exists()) {
                $categoryIds = Category::query()->whereIn('slug', $result['category_tags'])->pluck('categories_id')->all();
            }
        }

        $filled = array_keys($updates);
        if ($categoryIds !== null) {
            $filled[] = 'categories';
        }

        if ($filled !== []) {
            $updates['category_tags_reviewed'] = false;
        }

        // A cost does not reopen the tag review.
        if ($place->estimated_cost_idr === null && $result['estimated_cost_idr'] !== null) {
            $updates['estimated_cost_idr'] = $result['estimated_cost_idr'];
            $filled[] = 'estimated_cost_idr';
        }

        // Copied, not generated: Google Maps' own hours, only when the place has none.
        if (blank($place->opening_hours) && $mapsHours !== []) {
            $updates['opening_hours'] = OpeningHours::fromLines($mapsHours);
            $filled[] = 'opening_hours';
        }

        // Only when the place has none yet: keywords an admin wrote stay theirs.
        // Like the cost, they do not reopen the tag review.
        if (blank($place->search_keywords) && $result['search_keywords'] !== []) {
            $updates['search_keywords'] = Place::normalizeSearchKeywords(implode(', ', $result['search_keywords']));
            $filled[] = 'search_keywords';
        }

        return [
            'facts' => $facts,
            'answer' => $answer,
            'notes' => $notes,
            'updates' => $updates,
            'category_ids' => $categoryIds,
            'filled' => $filled,
        ];
    }

    /**
     * Checks Gemini's answer against the place type and the source facts.
     * A failed check drops the value (an empty field is better than a wrong
     * one); a clear OSM category replaces Gemini's indoor/outdoor guess.
     *
     * @return array{0: array, 1: array<int, string>} the cleaned answer and why values were dropped or changed
     */
    private function plausible(Place $place, array $answer, bool $hasSourceDescription, bool $hasFoundHours = false): array
    {
        $notes = [];
        $type = $place->type;

        if (! $hasSourceDescription && $answer['description_id'] !== null) {
            $reason = $this->descriptionProblem($answer['description_id'], $answer['description_confidence'], $place, $hasFoundHours);
            if ($reason !== null) {
                $notes[] = "deskripsi AI dibuang: {$reason}";
                $answer['description_id'] = null;
            }
        }

        // The English text translates the Indonesian one; with no description to translate, there is nothing to keep.
        if (! $hasSourceDescription && $answer['description_id'] === null && $answer['description_en'] !== null) {
            $answer['description_en'] = null;
        }

        if ($answer['estimated_visit_minutes'] !== null && isset(self::VISIT_MINUTES_RANGE[$type])
            && ! self::reasonableVisitMinutes($type, $answer['estimated_visit_minutes'])) {
            [$min, $max] = self::VISIT_MINUTES_RANGE[$type];
            $notes[] = "lama kunjungan {$answer['estimated_visit_minutes']} menit dibuang (wajar {$min}-{$max})";
            $answer['estimated_visit_minutes'] = null;
        }

        if ($answer['estimated_cost_idr'] !== null && isset(self::COST_RANGE[$type])
            && ! self::reasonableCost($type, $answer['estimated_cost_idr'])) {
            $notes[] = 'biaya Rp '.number_format($answer['estimated_cost_idr'], 0, ',', '.').' dibuang (di luar rentang wajar untuk jenis ini)';
            $answer['estimated_cost_idr'] = null;
        }

        $osmOutdoor = $this->osmOutdoor($place);
        if ($osmOutdoor !== null && $answer['is_outdoor'] !== $osmOutdoor) {
            $notes[] = 'is_outdoor diganti '.($osmOutdoor ? 'true' : 'false').' sesuai kategori OpenStreetMap'
                .($answer['is_outdoor'] === null ? '' : ' (AI menjawab '.($answer['is_outdoor'] ? 'true' : 'false').')');
            $answer['is_outdoor'] = $osmOutdoor;
        }

        return [$answer, $notes];
    }

    /**
     * Why a description Gemini wrote should not be kept, or null when it may.
     */
    private function descriptionProblem(string $text, ?string $confidence, Place $place, bool $hasFoundHours): ?string
    {
        if ($confidence === null || $confidence === 'rendah') {
            return 'AI tidak yakin mengenal tempat ini';
        }

        // The prompt forbids these unless the sources gave them; a price, a
        // phone number or opening hours in the text means it was made up.
        if (preg_match('/\bRp\.?\s?\d|\d+\s?(ribu|rb|juta)\b/iu', $text)) {
            return 'menyebut harga';
        }

        if (preg_match('/(\+62|\b0)8\d{2}[\s.-]?\d{3,}/', $text)) {
            return 'menyebut nomor telepon';
        }

        if (blank($place->opening_hours) && ! $hasFoundHours && preg_match('/\b\d{1,2}[.:]\d{2}\b/', $text)) {
            return 'menyebut jam padahal sumber tidak punya jam buka';
        }

        return null;
    }

    /**
     * True or false when the place's Geoapify categories settle it, else null.
     */
    private function osmOutdoor(Place $place): ?bool
    {
        $categories = is_array($place->types) ? $place->types : [];
        $matches = fn (array $prefixes) => collect($categories)->contains(
            fn ($category) => is_string($category) && collect($prefixes)->contains(
                fn (string $prefix) => $category === $prefix || str_starts_with($category, $prefix.'.')
            )
        );

        if ($matches(self::OUTDOOR_CATEGORIES)) {
            return true;
        }

        return $matches(self::INDOOR_CATEGORIES) ? false : null;
    }

    /**
     * What the data sources say about the place, one line each, for the prompt.
     *
     * @param  array<string, string>  $osmTags
     * @return array<int, string>
     */
    private function facts(Place $place, array $osmTags): array
    {
        $facts = [];

        $categories = collect(is_array($place->types) ? $place->types : [])->filter(fn ($category) => is_string($category));
        if ($categories->isNotEmpty()) {
            $facts[] = 'Kategori Geoapify/OpenStreetMap: '.$categories->take(8)->implode(', ');
        }

        foreach ($osmTags as $tag => $value) {
            $facts[] = "Tag OpenStreetMap {$tag}: {$value}";
        }

        $hours = OpeningHours::describe($place->opening_hours);
        if ($hours !== []) {
            $facts[] = 'Jam buka: '.implode('; ', $hours);
        }

        return $facts;
    }

    /**
     * Google Maps and the web, through SerpApi, when its quota allows an
     * automatic lookup. Without it the enrichment still runs on the other facts.
     */
    private function lookUpGoogle(Place $place): ?array
    {
        if (! $this->google->canLookUpAutomatically()) {
            return null;
        }

        try {
            return $this->google->lookUp($place);
        } catch (RuntimeException $exception) {
            Log::info("Pencarian Google place {$place->places_id} dilewati: {$exception->getMessage()}");

            return null;
        }
    }

    /**
     * Google Maps lines are facts; web snippets are marked as maybe about
     * another place or out of date.
     *
     * @return array<int, string>
     */
    private function googleFacts(?array $google): array
    {
        if ($google === null) {
            return [];
        }

        $facts = [];
        $maps = $google['maps'];
        if ($maps !== null) {
            if ($maps['types'] !== []) {
                $facts[] = 'Jenis di Google Maps: '.implode(', ', $maps['types']);
            }
            if ($maps['status']) {
                $facts[] = 'Status di Google Maps: '.$maps['status'];
            }
            if ($maps['hours'] !== []) {
                $facts[] = 'Jam buka di Google Maps: '.implode('; ', $maps['hours']);
            }
            if ($maps['price']) {
                $facts[] = 'Kisaran harga di Google Maps: '.$maps['price'];
            }
        }

        foreach ($google['web'] as $web) {
            $facts[] = 'Hasil web (belum tentu tentang tempat ini, perhatikan nama dan tahunnya) '
                .($web['source'] ?? 'web').($web['date'] ? ", {$web['date']}" : '').": {$web['title']}. {$web['snippet']}";
        }

        return $facts;
    }

    /**
     * OSM tags straight from Geoapify for a place found by Discovery (1
     * credit). Without them the prompt still has the stored facts, so a
     * failure here does not stop the enrichment.
     *
     * @return array<string, string>
     */
    private function lookUpOsmTags(Place $place): array
    {
        if (! is_string($place->external_place_id) || ! str_starts_with($place->external_place_id, 'osm:')) {
            return [];
        }

        try {
            return $this->geoapify->fetch($place->external_place_id)['osm_tags'] ?? [];
        } catch (RuntimeException $exception) {
            Log::info("Tag OSM place {$place->places_id} tidak terambil: {$exception->getMessage()}");

            return [];
        }
    }

    /**
     * The description shown in the app: the admin override wins over the
     * one from the data source.
     */
    private function sourceDescription(Place $place): ?string
    {
        foreach ([$place->description_override, $place->description] as $text) {
            if (filled($text)) {
                return trim($text);
            }
        }

        return null;
    }

    private function isLodging(Place $place): bool
    {
        return $place->type === 'lodging';
    }
}
