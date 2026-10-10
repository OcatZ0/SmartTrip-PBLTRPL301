<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TripWishlistPlace extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $primaryKey = 'trip_wishlist_places_id';

    protected $fillable = [
        'trips_id',
        'places_id',
        'custom_name',
        'custom_lat',
        'custom_lng',
        'custom_visit_minutes',
    ];

    protected function casts(): array
    {
        return [
            'custom_lat' => 'decimal:7',
            'custom_lng' => 'decimal:7',
        ];
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'trips_id');
    }

    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'places_id')->withTrashed();
    }
}
