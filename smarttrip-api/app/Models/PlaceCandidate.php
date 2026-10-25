<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Spatie\Activitylog\Models\Concerns\LogsActivity;
use Spatie\Activitylog\Support\LogOptions;

class PlaceCandidate extends Model
{
    use HasFactory, LogsActivity;

    protected $primaryKey = 'place_candidates_id';

    protected $fillable = [
        'external_place_id',
        'name',
        'type',
        'lat',
        'lng',
        'search_area',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'lat' => 'decimal:7',
            'lng' => 'decimal:7',
        ];
    }

    // Audit trail of curation decisions: who approved/rejected which candidate and when.
    public function getActivitylogOptions(): LogOptions
    {
        return LogOptions::defaults()
            ->logOnly(['name', 'status'])
            ->logOnlyDirty()
            ->dontLogEmptyChanges();
    }
}
