<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ItineraryDay extends Model
{
    use HasFactory;

    public const START_COLUMNS = ['start_places_id', 'start_custom_name', 'start_lat', 'start_lng'];

    public const END_COLUMNS = ['end_places_id', 'end_custom_name', 'end_lat', 'end_lng'];

    public $timestamps = false;

    protected $primaryKey = 'itinerary_days_id';

    protected $fillable = [
        'trips_id',
        'day_number',
        'start_places_id',
        'start_custom_name',
        'start_lat',
        'start_lng',
        'end_places_id',
        'end_custom_name',
        'end_lat',
        'end_lng',
        'polyline_to_end',
    ];

    protected function casts(): array
    {
        return [
            'start_lat' => 'decimal:7',
            'start_lng' => 'decimal:7',
            'end_lat' => 'decimal:7',
            'end_lng' => 'decimal:7',
        ];
    }

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class, 'trips_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(ItineraryItem::class, 'itinerary_days_id')->orderBy('visit_order');
    }

    public function startPlace(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'start_places_id')->withTrashed();
    }

    public function endPlace(): BelongsTo
    {
        return $this->belongsTo(Place::class, 'end_places_id')->withTrashed();
    }

    public function hasStart(): bool
    {
        return $this->start_places_id !== null || ($this->start_lat !== null && $this->start_lng !== null);
    }

    public function hasOwnEnd(): bool
    {
        return $this->end_places_id !== null || ($this->end_lat !== null && $this->end_lng !== null);
    }

    /**
     * @return array{lat: float, lng: float, name: ?string, places_id: ?int}|null
     */
    public function startPoint(): ?array
    {
        return $this->point('start', $this->startPlace);
    }

    /**
     * Where the day ends; its own start when no other end was set.
     *
     * @return array{lat: float, lng: float, name: ?string, places_id: ?int}|null
     */
    public function endPoint(): ?array
    {
        return $this->hasOwnEnd() ? $this->point('end', $this->endPlace) : $this->startPoint();
    }

    /**
     * @return array{lat: float, lng: float, name: ?string, places_id: ?int}|null
     */
    private function point(string $prefix, ?Place $place): ?array
    {
        if ($this->{$prefix.'_places_id'} !== null) {
            return $place ? [
                'lat' => (float) $place->lat,
                'lng' => (float) $place->lng,
                'name' => $place->name,
                'places_id' => $place->places_id,
            ] : null;
        }

        if ($this->{$prefix.'_lat'} === null || $this->{$prefix.'_lng'} === null) {
            return null;
        }

        return [
            'lat' => (float) $this->{$prefix.'_lat'},
            'lng' => (float) $this->{$prefix.'_lng'},
            'name' => $this->{$prefix.'_custom_name'},
            'places_id' => null,
        ];
    }
}
