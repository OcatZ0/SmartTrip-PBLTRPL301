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

    public const UPDATED_AT = null;

    protected $fillable = [
        'users_id',
        'title',
        'num_days',
        'budget_total',
        'has_own_hotel',
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

    public function isOwnedBy(User $user): bool
    {
        return $this->users_id === $user->users_id;
    }

    /**
     * docs/prd design spec Section 9: endpoint baca trip-scoped (wishlist,
     * itinerary, dst) dibuka untuk pemilik ATAU user dengan baris
     * trip_viewers - endpoint tulis tetap owner-only, tidak berubah.
     */
    public function isReadableBy(User $user): bool
    {
        return $this->isOwnedBy($user) || $this->viewers()->where('users.users_id', $user->users_id)->exists();
    }

    /**
     * Keeps one day row per trip day, 1..num_days: a new day starts where the
     * last one did, and days past num_days go with their stops.
     */
    public function syncDays(): void
    {
        $days = $this->days()->orderBy('day_number')->get();
        $this->days()->where('day_number', '>', $this->num_days)->delete();

        $last = $days->where('day_number', '<=', $this->num_days)->last();
        for ($dayNumber = 1; $dayNumber <= $this->num_days; $dayNumber++) {
            if ($days->contains('day_number', $dayNumber)) {
                continue;
            }

            $this->days()->create([
                'day_number' => $dayNumber,
                ...($last ? $last->only(ItineraryDay::START_COLUMNS) : []),
            ]);
        }

        $this->unsetRelation('days');
    }

    /**
     * Every day knows where it starts, which generating the itinerary needs.
     */
    public function hasDayStarts(): bool
    {
        $days = $this->days()->get();

        return $days->count() >= $this->num_days && $days->every(fn (ItineraryDay $day) => $day->hasStart());
    }
}
