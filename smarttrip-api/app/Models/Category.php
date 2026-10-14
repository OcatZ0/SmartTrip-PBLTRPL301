<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Spatie\Activitylog\LogOptions;
use Spatie\Activitylog\Traits\LogsActivity;

class Category extends Model
{
    use HasFactory, LogsActivity, SoftDeletes;

    protected $primaryKey = 'categories_id';

    protected $fillable = [
        'name_id',
        'subtitle_id',
        'name_en',
        'slug',
        'icon_symbol',
        'ai_keywords',
        'visibility_onboarding',
    ];

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
                'ai_keywords',
            ])
            ->logOnlyDirty()
            ->dontSubmitEmptyLogs();
    }

    public function activitiesAsSubject()
    {
        return \Spatie\Activitylog\Models\Activity::forSubject($this);
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
