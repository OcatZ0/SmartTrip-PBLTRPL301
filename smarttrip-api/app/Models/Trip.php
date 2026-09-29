<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Trip extends Model
{
    use HasFactory, SoftDeletes;

    protected $primaryKey = 'trips_id';

    protected $fillable = [
        'users_id',
        'title',
        'num_days',
        'budget_total',
        'has_own_hotel',
        'hotel_places_id',
        'hotel_custom_name',
        'hotel_lat',
        'hotel_lng',
        'start_date',
        'daily_start_time',
        'daily_end_time',
        'weight_kategori',
        'weight_jarak',
        'weight_anggaran',
        'weight_rating',
        'viewer_invite_token',
        'share_token',
    ];

    protected function casts(): array
    {
        return [
            'has_own_hotel' => 'boolean',
            'hotel_lat' => 'decimal:7',
            'hotel_lng' => 'decimal:7',
            'start_date' => 'date',
            'weight_kategori' => 'decimal:3',
            'weight_jarak' => 'decimal:3',
            'weight_anggaran' => 'decimal:3',
            'weight_rating' => 'decimal:3',
        ];
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'users_id');
    }

    public function hotelPlace(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'hotel_places_id');
    }

    public function interestCategories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'trip_interest_category', 'trips_id', 'categories_id');
    }

    public function wishlistPlaces(): HasMany
    {
        return $this->hasMany(TripWishlistPlace::class, 'trips_id');
    }

    public function days(): HasMany
    {
        return $this->hasMany(ItineraryDay::class, 'trips_id');
    }

    public function viewers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'trip_viewers', 'trips_id', 'users_id')
            ->withPivot('added_at');
    }
}
