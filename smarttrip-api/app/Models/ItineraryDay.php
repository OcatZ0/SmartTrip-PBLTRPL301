<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ItineraryDay extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $primaryKey = 'itinerary_days_id';

    protected $fillable = [
        'trips_id',
        'day_number',
    ];

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'trips_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(ItineraryItem::class, 'itinerary_days_id')->orderBy('visit_order');
    }
}
