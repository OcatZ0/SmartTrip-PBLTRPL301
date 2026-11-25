<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class PlacePhoto extends Model
{
    use HasFactory;

    public $timestamps = false;

    protected $primaryKey = 'place_photos_id';

    protected $fillable = [
        'places_id',
        'photo_url',
        'sort_order',
    ];

    /**
     * Photos saved on this server are stored as a public-disk path and get
     * the current APP_URL when read, so a domain move needs no data rewrite.
     * Anything else (links to other sites, a pasted cover URL) stays as stored.
     */
    public static function publicUrl(?string $stored): ?string
    {
        return self::isStoredHere($stored) ? Storage::disk('public')->url($stored) : $stored;
    }

    /**
     * The two public-disk folders this app writes photos to.
     */
    public static function isStoredHere(?string $stored): bool
    {
        return $stored !== null && preg_match('#^(place-photos|places)/#', $stored) === 1;
    }

    protected function photoUrl(): Attribute
    {
        return Attribute::get(fn (?string $value) => self::publicUrl($value));
    }

    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'places_id');
    }
}
