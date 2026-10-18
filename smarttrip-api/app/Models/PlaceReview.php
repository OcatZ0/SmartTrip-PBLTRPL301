<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class PlaceReview extends Model
{
    use HasFactory, SoftDeletes;

    protected $primaryKey = 'place_reviews_id';

    public const UPDATED_AT = null;

    protected $fillable = [
        'places_id',
        'users_id',
        'rating',
        'comment',
        'itinerary_items_id',
    ];

    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'places_id');
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'users_id');
    }

    public function itineraryItem(): BelongsTo
    {
        return $this->belongsTo(ItineraryItem::class, 'itinerary_items_id');
    }
}
