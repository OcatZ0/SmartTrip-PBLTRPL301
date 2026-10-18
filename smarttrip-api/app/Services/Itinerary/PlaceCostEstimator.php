<?php

namespace App\Services\Itinerary;

use App\Models\Place;
use Illuminate\Support\Collection;

/**
 * docs/prd design spec Section 7 langkah 5 (kriteria anggaran), 3 tingkat
 * fallback. Tingkat 3 (default per type) memang dicontohkan PRD (Rp 50.000
 * attraction/culinary, Rp 300.000 lodging). Tingkat Google price_level
 * dihapus 2026-10-18: Geoapify tidak punya data harga.
 */
class PlaceCostEstimator
{
    private const DEFAULT_FALLBACK = [
        'attraction' => 50000,
        'culinary' => 50000,
        'lodging' => 300000,
    ];

    /**
     * @param  Collection<int, Place>  $places  pool kandidat dipakai buat median tingkat 2 (harus 1 `type` yang sama)
     */
    public function __construct(private readonly Collection $places) {}

    public function estimate(Place $place): int
    {
        // Tingkat 1: estimated_cost_idr admin.
        if ($place->estimated_cost_idr !== null) {
            return (int) $place->estimated_cost_idr;
        }

        // Tingkat 2: median tempat lain di `type` yang sama yang datanya ada.
        $resolved = $this->places
            ->where('type', $place->type)
            ->pluck('estimated_cost_idr')
            ->filter(fn ($cost) => $cost !== null)
            ->map(fn ($cost) => (int) $cost)
            ->values();

        if ($resolved->isNotEmpty()) {
            return (int) $this->median($resolved->all());
        }

        // Tingkat 3: default hardcode per type.
        return self::DEFAULT_FALLBACK[$place->type] ?? 50000;
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
