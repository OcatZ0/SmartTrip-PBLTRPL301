<?php

namespace App\Services\Places;

use App\Models\Category;
use App\Models\Place;
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
 * guessed by Gemini is only written when the admin left it empty, and is
 * marked estimated_cost_is_ai instead.
 */
class PlaceEnrichmentService
{
    public function __construct(private readonly GeminiEnrichmentClient $gemini) {}

    /**
     * Whether a call to Gemini could still fill something on [place].
     */
    public function needsEnrichment(Place $place): bool
    {
        if ($this->sourceDescription($place) === null || blank($place->description_en) || $place->estimated_cost_idr === null) {
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
     * @return array<int, string> the fields that were filled, empty when
     *                            Gemini had nothing new
     *
     * @throws RuntimeException when Gemini cannot be reached or answers
     *                          something unusable
     */
    public function enrich(Place $place): array
    {
        $availableSlugs = Category::query()->pluck('slug')->all();
        $description = $this->sourceDescription($place);

        $result = $this->gemini->enrich($place->name, $description, $availableSlugs, [
            'type' => $place->type,
            'kecamatan' => $place->kecamatan,
            'address' => $place->address,
        ]);

        $updates = [];

        if ($description === null && $result['description_id'] !== null) {
            $updates['description'] = $result['description_id'];
        }

        if (blank($place->description_en) && filled($result['description_en'])) {
            $updates['description_en'] = $result['description_en'];
        }

        // Confirmed by an admin: keep their tags, duration and outdoor flag.
        $syncTags = false;
        if (! $place->category_tags_reviewed) {
            if ($place->estimated_visit_minutes === null && $result['estimated_visit_minutes'] !== null && ! $this->isLodging($place)) {
                $updates['estimated_visit_minutes'] = $result['estimated_visit_minutes'];
            }

            if ($place->is_outdoor === null && $result['is_outdoor'] !== null) {
                $updates['is_outdoor'] = $result['is_outdoor'];
            }

            // Interest categories drive TOPSIS for attractions and food;
            // hotels are picked separately in step C4.
            $syncTags = $result['category_tags'] !== []
                && ! $this->isLodging($place)
                && ! $place->categories()->exists();
        }

        $filled = array_keys($updates);

        if ($syncTags) {
            $categoryIds = Category::query()->whereIn('slug', $result['category_tags'])->pluck('categories_id');
            $place->categories()->sync($categoryIds);
            $filled[] = 'categories';
        }

        if ($filled !== []) {
            $updates['category_tags_reviewed'] = false;
        }

        // Has its own "Perkiraan AI" mark, so it does not reopen the tag review.
        if ($place->estimated_cost_idr === null && $result['estimated_cost_idr'] !== null) {
            $updates['estimated_cost_idr'] = $result['estimated_cost_idr'];
            $updates['estimated_cost_is_ai'] = true;
            $filled[] = 'estimated_cost_idr';
        }

        if ($updates !== []) {
            $place->update($updates);
        }

        return $filled;
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
