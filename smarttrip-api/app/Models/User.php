<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Mail\PasswordResetMail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\URL;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable, SoftDeletes;

    public $timestamps = false;

    /**
     * docs/prd Section 10 PK/FK naming convention: {table}_id, not `id`.
     */
    protected $primaryKey = 'users_id';

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'google_id',
        'email_verified_at',
        'default_weight_kategori',
        'default_weight_jarak',
        'default_weight_anggaran',
        'default_weight_rating',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'deleted_at' => 'datetime',
            'password' => 'hashed',
            'default_weight_kategori' => 'decimal:3',
            'default_weight_jarak' => 'decimal:3',
            'default_weight_anggaran' => 'decimal:3',
            'default_weight_rating' => 'decimal:3',
        ];
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function defaultInterestCategories(): BelongsToMany
    {
        return $this->belongsToMany(
            Category::class,
            'user_default_interest_category',
            'users_id',
            'categories_id'
        );
    }

    /**
     * Soft-deleted places drop out through Place's SoftDeletes scope, and
     * come back if the admin restores them.
     */
    public function wishlistPlaces(): BelongsToMany
    {
        return $this->belongsToMany(Place::class, 'user_wishlist_place', 'users_id', 'places_id')
            ->withPivot('added_at');
    }

    public function trips(): HasMany
    {
        return $this->hasMany(Trip::class, 'users_id');
    }

    public function placeReviews(): HasMany
    {
        return $this->hasMany(PlaceReview::class, 'users_id');
    }

    public function sharedTrips(): BelongsToMany
    {
        return $this->belongsToMany(Trip::class, 'trip_viewers', 'users_id', 'trips_id')
            ->withPivot('added_at');
    }

    /**
     * F004 (lupa password): default Laravel notification links to a
     * `password.reset` web route this app doesn't have (no SPA frontend) -
     * point it at our own reset form instead (see AuthController).
     */
    public function sendPasswordResetNotification($token): void
    {
        $url = URL::route('auth.reset-password.form', [
            'email' => $this->email,
            'token' => $token,
        ]);

        Mail::to($this->email)->send(new PasswordResetMail($url));
    }
}
