<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Place extends Model
{
    use HasFactory, SoftDeletes;

    protected $primaryKey = 'places_id';

    /**
     * Kolom kurasi admin (category_tags_reviewed..description_en, kecamatan)
     * WAJIB ditulis lewat whitelist eksplisit saat re-sync dari Google -
     * lihat docs/prd design spec Section 4. Jangan updateOrCreate() dengan
     * payload penuh dari Google di service sync nanti.
     */
    protected $fillable = [
        'google_place_id',
        'name',
        'type',
        'lat',
        'lng',
        'address',
        'kecamatan',
        'price_level',
        'rating',
        'review_count',
        'opening_hours',
        'photo_url',
        'description',
        'phone',
        'website',
        'business_status',
        'types',
        'source',
        'category_tags_reviewed',
        'estimated_visit_minutes',
        'is_outdoor',
        'estimated_cost_idr',
        'description_override',
        'description_en',
    ];

    protected function casts(): array
    {
        return [
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
            'rating' => 'decimal:2',
            'opening_hours' => 'array',
            'types' => 'array',
            'category_tags_reviewed' => 'boolean',
            'is_outdoor' => 'boolean',
        ];
    }

    public function categories(): BelongsToMany
    {
        return $this->belongsToMany(Category::class, 'place_category', 'places_id', 'categories_id');
    }

    public function photos(): HasMany
    {
        return $this->hasMany(PlacePhoto::class, 'places_id');
    }

    public function reviews(): HasMany
    {
        return $this->hasMany(PlaceReview::class, 'places_id');
    }

    public function wishlistedIn(): HasMany
    {
        return $this->hasMany(TripWishlistPlace::class, 'places_id');
    }

    public function itineraryItems(): HasMany
    {
        return $this->hasMany(ItineraryItem::class, 'places_id');
    }
}
