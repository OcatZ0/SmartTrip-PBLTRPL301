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
    ];

    protected function casts(): array
    {
        return [
            'topsis_score' => 'decimal:4',
            'visited_at' => 'datetime',
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

    public function review(): HasOne
    {
        return $this->hasOne(PlaceReview::class, 'itinerary_items_id');
    }
}
