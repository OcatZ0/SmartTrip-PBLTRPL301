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

    protected $fillable = [
        'name_id',
        'name_en',
        'slug',
    ];

    /**
     * F023 (Riwayat Perubahan) - sama seperti Place (F021), dipasang dari
     * sekarang supaya ada data begitu giliran F023 dibangun.
     */
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name_id', 'name_en', 'slug'])
            ->logOnlyDirty()
            ->dontLogEmptyChanges();
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
