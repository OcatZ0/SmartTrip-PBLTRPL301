<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Activitylog\Models\Concerns\LogsActivity;
use Spatie\Activitylog\Support\LogOptions;

class Category extends Model
{
    use HasFactory, LogsActivity, SoftDeletes;

    protected $primaryKey = 'categories_id';

    /** Default of categories.icon_symbol (migration 2026_10_09). */
    public const DEFAULT_ICON_SYMBOL = 'ombak';

    /**
     * Icons an admin can pick for a category: icon_symbol key => label,
     * Bootstrap Icons name, colour tone and extra search words. The keys are
     * what is stored, so existing keys must not be renamed.
     */
    public const ICON_SYMBOLS = [
        'ombak' => ['label' => 'Ombak', 'icon' => 'bi-tsunami', 'tone' => 'blue', 'search' => 'laut bahari air'],
        // Bootstrap Icons has no anchor (the earlier "bi-anchor" drew nothing).
        'feri' => ['label' => 'Feri', 'icon' => 'bi-life-preserver', 'tone' => 'blue', 'search' => 'kapal pelabuhan pompong'],
        'selam' => ['label' => 'Selam', 'icon' => 'bi-water', 'tone' => 'blue', 'search' => 'snorkeling diving karang'],
        'pantai' => ['label' => 'Pesisir', 'icon' => 'bi-umbrella-fill', 'tone' => 'blue', 'search' => 'pantai pasir payung'],
        'pulau' => ['label' => 'Pulau', 'icon' => 'bi-globe-asia-australia', 'tone' => 'blue', 'search' => 'island hopping'],
        'air' => ['label' => 'Air Terjun', 'icon' => 'bi-droplet-half', 'tone' => 'blue', 'search' => 'danau sungai waduk'],
        'senja' => ['label' => 'Senja', 'icon' => 'bi-sunset-fill', 'tone' => 'orange', 'search' => 'sunset sore'],
        'matahari' => ['label' => 'Cerah', 'icon' => 'bi-sun-fill', 'tone' => 'orange', 'search' => 'outdoor siang'],
        'alam' => ['label' => 'Alam', 'icon' => 'bi-tree-fill', 'tone' => 'green', 'search' => 'hutan nature'],
        'taman' => ['label' => 'Taman', 'icon' => 'bi-flower2', 'tone' => 'green', 'search' => 'kebun park'],
        'spa' => ['label' => 'Spa', 'icon' => 'bi-flower1', 'tone' => 'green', 'search' => 'relaksasi pijat wellness'],
        'kemah' => ['label' => 'Kemah', 'icon' => 'bi-fire', 'tone' => 'green', 'search' => 'camping api unggun'],
        'hiking' => ['label' => 'Hiking', 'icon' => 'bi-signpost-2-fill', 'tone' => 'green', 'search' => 'trekking bukit jalur'],
        'petualangan' => ['label' => 'Petualangan', 'icon' => 'bi-compass-fill', 'tone' => 'green', 'search' => 'adventure jelajah'],
        'sepeda' => ['label' => 'Olahraga', 'icon' => 'bi-bicycle', 'tone' => 'green', 'search' => 'sepeda sport'],
        'kuliner' => ['label' => 'Kuliner', 'icon' => 'bi-cup-hot-fill', 'tone' => 'amber', 'search' => 'makan seafood'],
        'restoran' => ['label' => 'Restoran', 'icon' => 'bi-egg-fried', 'tone' => 'amber', 'search' => 'makan malam'],
        'kafe' => ['label' => 'Kafe', 'icon' => 'bi-cup-straw', 'tone' => 'amber', 'search' => 'kopi minuman coffee'],
        'belanja' => ['label' => 'Belanja', 'icon' => 'bi-bag-fill', 'tone' => 'purple', 'search' => 'mall shopping duty free'],
        'pasar' => ['label' => 'Pasar', 'icon' => 'bi-shop', 'tone' => 'purple', 'search' => 'toko market'],
        'oleh' => ['label' => 'Oleh-oleh', 'icon' => 'bi-gift-fill', 'tone' => 'purple', 'search' => 'suvenir hadiah'],
        'budaya' => ['label' => 'Budaya', 'icon' => 'bi-bank2', 'tone' => 'indigo', 'search' => 'tradisi adat'],
        'sejarah' => ['label' => 'Sejarah', 'icon' => 'bi-hourglass-split', 'tone' => 'indigo', 'search' => 'history monumen'],
        'museum' => ['label' => 'Museum', 'icon' => 'bi-easel-fill', 'tone' => 'indigo', 'search' => 'galeri pameran'],
        'seni' => ['label' => 'Seni', 'icon' => 'bi-palette-fill', 'tone' => 'indigo', 'search' => 'art lukisan'],
        'religi' => ['label' => 'Religi', 'icon' => 'bi-bookmark-star-fill', 'tone' => 'indigo', 'search' => 'masjid vihara gereja ibadah'],
        'landmark' => ['label' => 'Landmark', 'icon' => 'bi-geo-alt-fill', 'tone' => 'red', 'search' => 'ikon jembatan'],
        'foto' => ['label' => 'Spot Foto', 'icon' => 'bi-camera-fill', 'tone' => 'red', 'search' => 'instagramable fotografi'],
        'romantis' => ['label' => 'Romantis', 'icon' => 'bi-heart-fill', 'tone' => 'red', 'search' => 'pasangan honeymoon'],
        'populer' => ['label' => 'Populer', 'icon' => 'bi-star-fill', 'tone' => 'red', 'search' => 'favorit top'],
        'keluarga' => ['label' => 'Keluarga', 'icon' => 'bi-people-fill', 'tone' => 'teal', 'search' => 'family rombongan'],
        'anak' => ['label' => 'Anak', 'icon' => 'bi-balloon-fill', 'tone' => 'teal', 'search' => 'kids bermain'],
        'hiburan' => ['label' => 'Hiburan', 'icon' => 'bi-controller', 'tone' => 'teal', 'search' => 'rekreasi permainan'],
        'acara' => ['label' => 'Acara', 'icon' => 'bi-calendar-event-fill', 'tone' => 'teal', 'search' => 'event festival'],
        'malam' => ['label' => 'Malam', 'icon' => 'bi-moon-stars-fill', 'tone' => 'slate', 'search' => 'nightlife'],
        'musik' => ['label' => 'Musik', 'icon' => 'bi-music-note-beamed', 'tone' => 'slate', 'search' => 'konser live'],
        'kota' => ['label' => 'Kota', 'icon' => 'bi-buildings-fill', 'tone' => 'slate', 'search' => 'urban gedung'],
        'penginapan' => ['label' => 'Penginapan', 'icon' => 'bi-house-heart-fill', 'tone' => 'slate', 'search' => 'hotel resort villa'],
        'transport' => ['label' => 'Transportasi', 'icon' => 'bi-bus-front-fill', 'tone' => 'slate', 'search' => 'bus terminal'],
        'pesawat' => ['label' => 'Bandara', 'icon' => 'bi-airplane-fill', 'tone' => 'slate', 'search' => 'airport terbang'],
    ];

    protected $fillable = [
        'name_id',
        'subtitle_id',
        'name_en',
        'slug',
        'icon_symbol',
        'show_in_onboarding',
    ];

    protected function casts(): array
    {
        return [
            'show_in_onboarding' => 'boolean',
        ];
    }

    /**
     * F023 (Riwayat Perubahan) - sama seperti Place (F021), dipasang dari
     * sekarang supaya ada data begitu giliran F023 dibangun.
     */
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly([
                'name_id',
                'subtitle_id',
                'name_en',
                'slug',
                'icon_symbol',
                'show_in_onboarding',
            ])
            ->logOnlyDirty()
            ->dontLogEmptyChanges();
    }

    /**
     * Icon shown for this category in the admin list. Rows that still have
     * the column default (set for every existing row when the column was
     * added) get an icon guessed from the name, as the list did before.
     */
    public function iconMeta(): array
    {
        $symbol = $this->icon_symbol;

        if (($symbol === null || $symbol === self::DEFAULT_ICON_SYMBOL) && ($guess = $this->guessIconSymbol())) {
            $symbol = $guess;
        }

        return ['key' => $symbol] + (self::ICON_SYMBOLS[$symbol] ?? self::ICON_SYMBOLS[self::DEFAULT_ICON_SYMBOL]);
    }

    private function guessIconSymbol(): ?string
    {
        $name = mb_strtolower($this->name_id ?? '');

        // First match wins, so the more specific words come first.
        foreach (['feri' => 'feri', 'pantai' => 'pantai', 'seafood' => 'kuliner', 'lokal' => 'restoran', 'kuliner' => 'kuliner',
            'belanja' => 'belanja', 'sejarah' => 'sejarah', 'budaya' => 'budaya', 'religi' => 'religi', 'alam' => 'alam',
            'keluarga' => 'keluarga', 'malam' => 'malam', 'spa' => 'spa', 'foto' => 'foto', 'landmark' => 'landmark',
            'taman' => 'taman', 'rekreasi' => 'hiburan'] as $word => $key) {
            if (str_contains($name, $word)) {
                return $key;
            }
        }

        return null;
    }

    public function places(): BelongsToMany
    {
        return $this->belongsToMany(Place::class, 'place_category', 'categories_id', 'places_id');
    }

    public function trips(): BelongsToMany
    {
        return $this->belongsToMany(Trip::class, 'trip_interest_category', 'categories_id', 'trips_id');
    }
}
