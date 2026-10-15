<?php

namespace App\Services\Itinerary;

/**
 * Kesesuaian kategori/minat (docs/prd design spec Section 7 langkah 5).
 */
class JaccardSimilarity
{
    /**
     * @param  array<int, int>  $firstIds
     * @param  array<int, int>  $secondIds
     */
    public static function of(array $firstIds, array $secondIds): float
    {
        $setA = array_unique($firstIds);
        $setB = array_unique($secondIds);

        $union = array_unique(array_merge($setA, $setB));
        if ($union === []) {
            return 0.0;
        }

        $intersection = array_intersect($setA, $setB);

        return count($intersection) / count($union);
    }
}
