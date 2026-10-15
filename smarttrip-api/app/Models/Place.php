<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Activitylog\Models\Concerns\LogsActivity;
use Spatie\Activitylog\Support\LogOptions;

class Place extends Model
{
    use HasFactory, LogsActivity, SoftDeletes;

    protected $primaryKey = 'places_id';

    /**
     * Kolom kurasi admin (category_tags_reviewed..description_en, kecamatan)
     * WAJIB ditulis lewat whitelist eksplisit saat re-sync dari Google -
     * lihat docs/prd design spec Section 4. Jangan updateOrCreate() dengan
     * payload penuh dari Google di service sync nanti.
     */
    protected $fillable = [
        'external_place_id',
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

    /**
     * F023 (Riwayat Perubahan) - cuma catat kolom yang memang bisa diedit
     * admin (docs/prd design spec Section 14), bukan kolom hasil sync
     * Google - supaya log tidak banjir tiap places:sync jalan.
     */
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly([
                'name', 'type', 'address', 'kecamatan',
                'estimated_cost_idr', 'description_override', 'description_en',
                'estimated_visit_minutes', 'is_outdoor', 'category_tags_reviewed',
            ])
            ->logOnlyDirty()
            ->dontLogEmptyChanges();
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

    /**
     * docs/prd design spec Section 6: Bayesian blend Google + in-app rating,
     * dekat ke rating Google saat review in-app masih sedikit/nol, makin
     * condong ke rata-rata in-app seiring jumlah review in-app bertambah
     * (mencegah 1 review 5 bintang baru mengalahkan tempat dengan ribuan
     * review Google). PRD tidak menetapkan angka `$priorWeight` (ambang "cukup
     * review") secara eksplisit - 10 dipilih sebagai asumsi wajar.
     *
     * Butuh `reviews_avg_rating`/`reviews_count` sudah di-load lewat
     * withAvg('reviews','rating')/withCount('reviews') di query pemanggil,
     * supaya tidak N+1.
     */
    public function ratingBlend(int $priorWeight = 10): ?float
    {
        $googleRating = $this->rating !== null ? (float) $this->rating : null;
        $inAppCount = (int) ($this->reviews_count ?? 0);
        $inAppAvg = $this->reviews_avg_rating !== null ? (float) $this->reviews_avg_rating : null;

        if ($googleRating === null && $inAppCount === 0) {
            return null;
        }

        if ($googleRating === null) {
            return round($inAppAvg, 2);
        }

        if ($inAppCount === 0) {
            return round($googleRating, 2);
        }

        return round(($inAppCount / ($inAppCount + $priorWeight)) * $inAppAvg + ($priorWeight / ($inAppCount + $priorWeight)) * $googleRating, 2);
    }
}
