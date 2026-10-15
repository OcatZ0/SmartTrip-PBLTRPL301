<?php

namespace App\Services\Itinerary;

/**
 * K-Means atas koordinat (docs/prd design spec Section 7 langkah 6a),
 * k = num_days. Inisialisasi deterministik (titik ber-spasi merata dari
 * daftar terurut) - bukan random - supaya hasilnya reproducible dan bisa
 * di-unit-test.
 */
class KMeans
{
    /**
     * @param  array<int, array{lat: float, lng: float}>  $points
     * @return array<int, int> index cluster (0-based) per titik, urutan sama seperti $points
     */
    public static function cluster(array $points, int $clusterCount, int $maxIterations = 100): array
    {
        $pointCount = count($points);

        if ($pointCount === 0) {
            return [];
        }

        $clusterCount = min($clusterCount, $pointCount);
        if ($clusterCount <= 1) {
            return array_fill(0, $pointCount, 0);
        }

        $sorted = $points;
        usort($sorted, fn ($left, $right) => $left['lat'] <=> $right['lat'] ?: $left['lng'] <=> $right['lng']);

        $centroids = [];
        for ($clusterIndex = 0; $clusterIndex < $clusterCount; $clusterIndex++) {
            $index = (int) floor($clusterIndex * ($pointCount - 1) / max($clusterCount - 1, 1));
            $centroids[$clusterIndex] = $sorted[$index];
        }

        $assignments = array_fill(0, $pointCount, -1);

        for ($iteration = 0; $iteration < $maxIterations; $iteration++) {
            $changed = false;

            foreach ($points as $pointIndex => $point) {
                $bestCluster = 0;
                $bestDistance = null;
                foreach ($centroids as $clusterIndex => $centroid) {
                    $distance = Haversine::km($point['lat'], $point['lng'], $centroid['lat'], $centroid['lng']);
                    if ($bestDistance === null || $distance < $bestDistance) {
                        $bestDistance = $distance;
                        $bestCluster = $clusterIndex;
                    }
                }

                if ($assignments[$pointIndex] !== $bestCluster) {
                    $assignments[$pointIndex] = $bestCluster;
                    $changed = true;
                }
            }

            if (! $changed) {
                break;
            }

            for ($clusterIndex = 0; $clusterIndex < $clusterCount; $clusterIndex++) {
                $members = array_filter($points, fn ($pointIndex) => $assignments[$pointIndex] === $clusterIndex, ARRAY_FILTER_USE_KEY);
                if ($members === []) {
                    continue;
                }
                $centroids[$clusterIndex] = [
                    'lat' => array_sum(array_column($members, 'lat')) / count($members),
                    'lng' => array_sum(array_column($members, 'lng')) / count($members),
                ];
            }
        }

        return $assignments;
    }

    /**
     * @param  array<int, array{lat: float, lng: float}>  $points
     * @return array{lat: float, lng: float}
     */
    public static function centroid(array $points): array
    {
        $count = count($points);

        return [
            'lat' => array_sum(array_column($points, 'lat')) / $count,
            'lng' => array_sum(array_column($points, 'lng')) / $count,
        ];
    }
}
