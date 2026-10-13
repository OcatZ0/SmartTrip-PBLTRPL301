<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class ItineraryItem extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $primaryKey = 'itinerary_items_id';

    protected $fillable = [
        'itinerary_days_id',
        'places_id',
        'visit_order',
        'topsis_score',
        'source',
        'polyline_to_here',
        'visited_at',
        'custom_name',
        'custom_lat',
        'custom_lng',
        'custom_visit_minutes',
    ];

    protected function casts(): array
    {
        return [
            'topsis_score' => 'decimal:4',
            'visited_at' => 'datetime',
            'custom_lat' => 'decimal:7',
            'custom_lng' => 'decimal:7',
        ];
    }

    public function day(): BelongsTo
    {
        return $this->belongsTo(ItineraryDay::class, 'itinerary_days_id');
    }

    public function place(): BelongsTo
    {
        // Riwayat trip harus tetap utuh walau admin soft-delete tempatnya
        // (docs/prd Section 10 soft delete policy).
        return $this->belongsTo(Place::class, 'places_id')->withTrashed();
    }

    /**
     * A stop is either a catalog place or a custom wishlist pin (places_id
     * null, custom_* filled - migration 2026_10_13_000000).
     *
     * @return array{lat: float, lng: float}
     */
    public function coordinates(): array
    {
        if ($this->places_id === null) {
            return ['lat' => (float) $this->custom_lat, 'lng' => (float) $this->custom_lng];
        }

        return ['lat' => (float) $this->place->lat, 'lng' => (float) $this->place->lng];
    }

    public function visitMinutes(): int
    {
        if ($this->places_id === null) {
            return (int) $this->custom_visit_minutes;
        }

        return (int) ($this->place->estimated_visit_minutes ?? 60);
    }

    public function review(): HasOne
    {
        return $this->hasOne(PlaceReview::class, 'itinerary_items_id');
    }
}
