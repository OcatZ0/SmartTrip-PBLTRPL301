<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

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

    public function place(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'places_id');
    }
}
