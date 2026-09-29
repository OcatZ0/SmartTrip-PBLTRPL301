<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * F007. `source` dibedakan `catalog` (places_id terisi, dari katalog)
 * atau `custom` (pin manual di peta) - bukan kolom DB, cuma turunan.
 */
class WishlistItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'trip_wishlist_places_id' => $this->trip_wishlist_places_id,
            'source' => $this->places_id !== null ? 'catalog' : 'custom',
            'place' => $this->whenLoaded('place', fn () => $this->place === null ? null : [
                'places_id' => $this->place->places_id,
                'name' => $this->place->name,
                'type' => $this->place->type,
                'photo_url' => $this->place->photo_url,
                'lat' => (float) $this->place->lat,
                'lng' => (float) $this->place->lng,
                'estimated_visit_minutes' => $this->place->estimated_visit_minutes,
                'rating' => $this->place->ratingBlend(),
            ]),
            'custom_name' => $this->custom_name,
            'custom_lat' => $this->custom_lat !== null ? (float) $this->custom_lat : null,
            'custom_lng' => $this->custom_lng !== null ? (float) $this->custom_lng : null,
            'custom_visit_minutes' => $this->custom_visit_minutes,
        ];
    }
}
