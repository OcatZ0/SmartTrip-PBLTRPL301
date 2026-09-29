<?php

namespace App\Services\Itinerary;

/**
 * Kesesuaian kategori/minat (docs/prd design spec Section 7 langkah 5).
 */
class JaccardSimilarity
{
    /**
     * @param  array<int, int>  $a
     * @param  array<int, int>  $b
     */
    public static function of(array $a, array $b): float
    {
        $setA = array_unique($a);
        $setB = array_unique($b);

        $union = array_unique(array_merge($setA, $setB));
        if ($union === []) {
            return 0.0;
        }

        $intersection = array_intersect($setA, $setB);

        return count($intersection) / count($union);
    }
}
