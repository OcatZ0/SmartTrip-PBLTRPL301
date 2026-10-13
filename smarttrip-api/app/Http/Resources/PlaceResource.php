<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * F005 - kartu katalog (PlaceCard). Sengaja tidak mengekspos kolom
 * internal admin/sync (external_place_id, source, category_tags_reviewed).
 */
class PlaceResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'places_id' => $this->places_id,
            'name' => $this->name,
            'type' => $this->type,
            'kecamatan' => $this->kecamatan,
            'lat' => (float) $this->lat,
            'lng' => (float) $this->lng,
            'photo_url' => $this->photo_url,
            'rating' => $this->ratingBlend(),
            'rating_google' => $this->rating !== null ? (float) $this->rating : null,
            'review_count_google' => $this->review_count,
            'review_count_in_app' => (int) ($this->reviews_count ?? 0),
            'price_level' => $this->price_level,
            'estimated_cost_idr' => $this->estimated_cost_idr,
            'is_outdoor' => $this->is_outdoor,
            'business_status' => $this->business_status,
            'categories' => $this->whenLoaded('categories', fn () => $this->categories->map(fn ($category) => [
                'categories_id' => $category->categories_id,
                'name_id' => $category->name_id,
                'name_en' => $category->name_en,
                'slug' => $category->slug,
            ])),
        ];
    }
}
