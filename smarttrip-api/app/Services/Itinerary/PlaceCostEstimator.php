<?php

namespace App\Services\Itinerary;

use App\Models\Place;
use Illuminate\Support\Collection;

/**
 * docs/prd design spec Section 7 langkah 5 (kriteria anggaran), 4 tingkat
 * fallback. Tingkat 2 (mapping price_level->IDR) dan tingkat 4 (default
 * hardcode per type) pakai angka asumsi karena PRD tidak menetapkan
 * nominal pasti untuk price_level - tingkat 4 memang eksplisit dicontohkan
 * PRD (Rp 50.000 attraction/culinary, Rp 300.000 lodging).
 */
class PlaceCostEstimator
{
    private const PRICE_LEVEL_MAP = [
        '0' => 0, 'PRICE_LEVEL_FREE' => 0,
        '1' => 25000, 'PRICE_LEVEL_INEXPENSIVE' => 25000,
        '2' => 75000, 'PRICE_LEVEL_MODERATE' => 75000,
        '3' => 200000, 'PRICE_LEVEL_EXPENSIVE' => 200000,
        '4' => 500000, 'PRICE_LEVEL_VERY_EXPENSIVE' => 500000,
    ];

    private const DEFAULT_FALLBACK = [
        'attraction' => 50000,
        'culinary' => 50000,
        'lodging' => 300000,
    ];

    /**
     * @param  Collection<int, Place>  $places  pool kandidat dipakai buat median tingkat 3 (harus 1 `type` yang sama)
     */
    public function __construct(private readonly Collection $places) {}

    public function estimate(Place $place): int
    {
        // Tingkat 1: estimated_cost_idr admin.
        if ($place->estimated_cost_idr !== null) {
            return (int) $place->estimated_cost_idr;
        }

        // Tingkat 2: mapping price_level.
        if ($place->price_level !== null && array_key_exists($place->price_level, self::PRICE_LEVEL_MAP)) {
            return self::PRICE_LEVEL_MAP[$place->price_level];
        }

        // Tingkat 3: median tempat lain di `type` yang sama yang datanya ada.
        $resolved = $this->places
            ->where('type', $place->type)
            ->map(fn (Place $place) => $this->resolveWithoutMedian($place))
            ->filter(fn ($cost) => $cost !== null)
            ->values();

        if ($resolved->isNotEmpty()) {
            return (int) $this->median($resolved->all());
        }

        // Tingkat 4: default hardcode per type.
        return self::DEFAULT_FALLBACK[$place->type] ?? 50000;
    }

    private function resolveWithoutMedian(Place $place): ?int
    {
        if ($place->estimated_cost_idr !== null) {
            return (int) $place->estimated_cost_idr;
        }

        if ($place->price_level !== null && array_key_exists($place->price_level, self::PRICE_LEVEL_MAP)) {
            return self::PRICE_LEVEL_MAP[$place->price_level];
        }

        return null;
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
