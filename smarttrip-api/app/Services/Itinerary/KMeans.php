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
    public static function cluster(array $points, int $k, int $maxIterations = 100): array
    {
        $n = count($points);

        if ($n === 0) {
            return [];
        }

        $k = min($k, $n);
        if ($k <= 1) {
            return array_fill(0, $n, 0);
        }

        $sorted = $points;
        usort($sorted, fn ($a, $b) => $a['lat'] <=> $b['lat'] ?: $a['lng'] <=> $b['lng']);

        $centroids = [];
        for ($i = 0; $i < $k; $i++) {
            $index = (int) floor($i * ($n - 1) / max($k - 1, 1));
            $centroids[$i] = $sorted[$index];
        }

        $assignments = array_fill(0, $n, -1);

        for ($iteration = 0; $iteration < $maxIterations; $iteration++) {
            $changed = false;

            foreach ($points as $i => $point) {
                $bestCluster = 0;
                $bestDistance = null;
                foreach ($centroids as $c => $centroid) {
                    $distance = Haversine::km($point['lat'], $point['lng'], $centroid['lat'], $centroid['lng']);
                    if ($bestDistance === null || $distance < $bestDistance) {
                        $bestDistance = $distance;
                        $bestCluster = $c;
                    }
                }

                if ($assignments[$i] !== $bestCluster) {
                    $assignments[$i] = $bestCluster;
                    $changed = true;
                }
            }

            if (! $changed) {
                break;
            }

            for ($c = 0; $c < $k; $c++) {
                $members = array_filter($points, fn ($_, $i) => $assignments[$i] === $c, ARRAY_FILTER_USE_BOTH);
                if ($members === []) {
                    continue;
                }
                $centroids[$c] = [
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
