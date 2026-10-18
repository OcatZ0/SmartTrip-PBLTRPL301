<?php

namespace App\Http\Resources;

use App\Services\Places\OpeningHours;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * F006 - layar detail tempat (foto carousel, deskripsi bilingual, rating
 * blend). description_override menang atas description mentah Google
 * kalau admin sudah isi, sesuai docs/prd design spec Section 4.
 */
class PlaceDetailResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'places_id' => $this->places_id,
            'name' => $this->name,
            'type' => $this->type,
            'address' => $this->address,
            'kecamatan' => $this->kecamatan,
            'lat' => (float) $this->lat,
            'lng' => (float) $this->lng,
            'maps_url' => "https://www.google.com/maps/search/?api=1&query={$this->lat},{$this->lng}",
            'photo_url' => $this->photo_url,
            'photos' => $this->whenLoaded('photos', fn () => $this->photos
                ->sortBy('sort_order')
                ->map(fn ($photo) => ['url' => $photo->photo_url])
                ->values()),
            'description_id' => $this->description_override ?? $this->description,
            'description_en' => $this->description_en,
            // The app shows these lines; places.opening_hours keeps only the hours per day.
            'opening_hours' => $this->opening_hours === null ? null : ['weekday_descriptions' => OpeningHours::describe($this->opening_hours)],
            'business_status' => $this->business_status,
            'rating' => $this->ratingBlend(),
            'review_count_in_app' => (int) ($this->reviews_count ?? 0),
            'estimated_cost_idr' => $this->estimated_cost_idr,
            'is_outdoor' => $this->is_outdoor,
            // B2 "Lama kunjungan" fact; the same estimate the generator uses.
            'estimated_visit_minutes' => $this->estimated_visit_minutes,
            'categories' => $this->whenLoaded('categories', fn () => $this->categories->map(fn ($category) => [
                'categories_id' => $category->categories_id,
                'name_id' => $category->name_id,
                'name_en' => $category->name_en,
                'slug' => $category->slug,
            ])),
            'reviews' => $this->whenLoaded('reviews', fn () => $this->reviews->map(fn ($review) => [
                'place_reviews_id' => $review->place_reviews_id,
                'users_id' => $review->users_id,
                'user_name' => $review->user?->name,
                'rating' => $review->rating,
                'comment' => $review->comment,
                'created_at' => $review->created_at,
            ])),
        ];
    }
}
