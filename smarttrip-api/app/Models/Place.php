<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
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
        'search_keywords',
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
    /**
     * What a place can still be missing: the dashboard's "Data belum
     * lengkap" card, the ?kurang= filter and the yellow rows on Kelola
     * Tempat. Label, why it matters, short name for a row.
     */
    public const DATA_GAPS = [
        'tag' => ['Tag kategori belum dicek', 'Usulan AI, perlu dikonfirmasi admin', 'tag belum dicek'],
        'harga' => ['Belum ada harga', 'Kriteria anggaran di itinerary', 'harga'],
        'jam' => ['Belum ada jam operasional', 'Agar itinerary tidak memilih hari tutup', 'jam buka'],
        'foto' => ['Belum ada foto', 'Tampil di katalog aplikasi', 'foto'],
        'durasi' => ['Belum ada lama kunjungan', 'Menentukan muat tidaknya satu hari', 'lama kunjungan'],
        'deskripsi_en' => ['Belum ada deskripsi English', 'Untuk wisatawan berbahasa Inggris', 'deskripsi English'],
        'kata_kunci' => ['Belum ada kata kunci pencarian', 'Agar tempat ditemukan di katalog', 'kata kunci'],
    ];

    /**
     * The DATA_GAPS this place has, the same rules as scopeMissing().
     *
     * @return array<int, string>
     */
    public function missingDataGaps(): array
    {
        return array_values(array_filter(array_keys(self::DATA_GAPS), fn (string $gap) => match ($gap) {
            'tag' => ! $this->category_tags_reviewed,
            'harga' => $this->estimated_cost_idr === null,
            'jam' => $this->opening_hours === null,
            'foto' => blank($this->photo_url),
            'durasi' => $this->estimated_visit_minutes === null && $this->type !== 'lodging',
            'deskripsi_en' => blank($this->description_en),
            'kata_kunci' => blank($this->search_keywords),
        }));
    }

    /**
     * Places missing one of DATA_GAPS. Hotels need no visit length.
     */
    public function scopeMissing(Builder $query, string $gap): Builder
    {
        $blank = fn (string $column) => fn (Builder $inner) => $inner->whereNull($column)->orWhere($column, '');

        return match ($gap) {
            'tag' => $query->where('category_tags_reviewed', false),
            'harga' => $query->whereNull('estimated_cost_idr'),
            'jam' => $query->whereNull('opening_hours'),
            'foto' => $query->where($blank('photo_url')),
            'durasi' => $query->whereNull('estimated_visit_minutes')->where('type', '!=', 'lodging'),
            'deskripsi_en' => $query->where($blank('description_en')),
            'kata_kunci' => $query->where($blank('search_keywords')),
            default => $query,
        };
    }

    /**
     * Places missing at least one of DATA_GAPS.
     */
    public function scopeIncomplete(Builder $query): Builder
    {
        return $query->where(function (Builder $any) {
            foreach (array_keys(self::DATA_GAPS) as $gap) {
                $any->orWhere(fn (Builder $one) => $one->missing($gap));
            }
        });
    }

    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly([
                'name', 'type', 'address', 'kecamatan',
                'estimated_cost_idr', 'description_override', 'description_en',
                'estimated_visit_minutes', 'is_outdoor', 'category_tags_reviewed', 'search_keywords',
                'opening_hours', 'business_status',
            ])
            ->logOnlyDirty()
            ->dontLogEmptyChanges();
    }

    /**
     * opening_hours as text, one line per day (see OpeningHours for the
     * stored shape). Older Geoapify places hold {"osm": "Mo-Su 08:00-21:00"}.
     */
    public function openingHoursText(): string
    {
        $hours = $this->opening_hours;
        if (! is_array($hours)) {
            return '';
        }

        if (is_array($hours['weekday_descriptions'] ?? null)) {
            return implode("\n", array_filter($hours['weekday_descriptions'], 'is_string'));
        }

        return is_string($hours['osm'] ?? null) ? $hours['osm'] : '';
    }

    /** search_keywords as a list, e.g. "pulau, diving" -> ["pulau", "diving"]. */
    public function searchKeywordList(): array
    {
        return array_values(array_filter(array_map('trim', explode(',', (string) $this->search_keywords)), fn ($keyword) => $keyword !== ''));
    }

    /**
     * Comma-separated keywords as stored: "pulau,  Diving,pulau" becomes
     * "pulau, Diving" (trimmed, no empty or repeated entries), null when empty.
     */
    public static function normalizeSearchKeywords(?string $keywords): ?string
    {
        $unique = [];
        foreach (explode(',', (string) $keywords) as $keyword) {
            $keyword = trim($keyword);
            if ($keyword !== '' && ! isset($unique[mb_strtolower($keyword)])) {
                $unique[mb_strtolower($keyword)] = $keyword;
            }
        }

        return $unique === [] ? null : implode(', ', $unique);
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
