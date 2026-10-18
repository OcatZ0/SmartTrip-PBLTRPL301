<?php

namespace App\Services\Itinerary;

use App\Models\Place;
use Illuminate\Support\Collection;

/**
 * docs/prd design spec Section 7 langkah 5 (kriteria rating), 3 tingkat
 * fallback - pola yang sama dengan PlaceCostEstimator. Tempat tanpa ulasan
 * in-app tidak punya rating; tanpa fallback nilainya jatuh ke 0.0, yang
 * menghukumnya ke posisi terburuk di kriteria rating.
 */
class PlaceRatingEstimator
{
    public const NEUTRAL_FALLBACK = 3.5;

    /**
     * @param  Collection<int, Place>  $places  pool kandidat dipakai buat median tingkat 2 (per `type`)
     */
    public function __construct(private readonly Collection $places) {}

    public function estimate(Place $place): float
    {
        // Tingkat 1: rata-rata ulasan in-app.
        $blend = $place->ratingBlend();
        if ($blend !== null) {
            return $blend;
        }

        // Tingkat 2: median rating tempat lain di `type` yang sama yang punya ulasan.
        $resolved = $this->places
            ->where('type', $place->type)
            ->map(fn (Place $place) => $place->ratingBlend())
            ->filter(fn ($rating) => $rating !== null)
            ->values();

        if ($resolved->isNotEmpty()) {
            return round($this->median($resolved->all()), 2);
        }

        // Tingkat 3: nilai netral, tempat tidak dihukum maupun diuntungkan.
        return self::NEUTRAL_FALLBACK;
    }

    private function median(array $values): float
    {
        sort($values);
        $count = count($values);
        $middle = (int) floor($count / 2);

        if ($count % 2 === 0) {
            return ($values[$middle - 1] + $values[$middle]) / 2;
        }

        return $values[$middle];
    }
}
