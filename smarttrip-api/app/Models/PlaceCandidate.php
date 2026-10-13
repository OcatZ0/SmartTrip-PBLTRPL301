<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlaceCandidate extends Model
{
    use HasFactory;

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
}
