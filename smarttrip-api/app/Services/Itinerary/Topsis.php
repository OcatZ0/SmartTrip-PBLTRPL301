<?php

namespace App\Services\Itinerary;

/**
 * Weighted-TOPSIS generik (docs/prd design spec Section 7 langkah 5).
 * Vector-normalize -> weighted -> jarak ke ideal terbaik/terburuk ->
 * closeness coefficient (0-1, makin besar makin baik).
 */
class Topsis
{
    /**
     * @param  array<int, array<string, float>>  $matrix  baris = alternatif (keyed apa saja, mis. places_id), kolom = kriteria
     * @param  array<string, float>  $weights  bobot per kriteria, jumlah idealnya 1
     * @param  array<string, bool>  $isBenefit  true = benefit (maksimalkan), false = cost (minimalkan)
     * @return array<int|string, float> closeness coefficient per baris, key sama seperti $matrix
     */
    public static function rank(array $matrix, array $weights, array $isBenefit): array
    {
        if ($matrix === []) {
            return [];
        }

        $criteria = array_keys($weights);

        // Vector normalization per kolom: r_ij = x_ij / sqrt(sum(x_ij^2))
        $denominators = [];
        foreach ($criteria as $criterion) {
            $sumSquares = 0.0;
            foreach ($matrix as $row) {
                $sumSquares += ($row[$criterion] ?? 0.0) ** 2;
            }
            $denominators[$criterion] = sqrt($sumSquares);
        }

        $weighted = [];
        foreach ($matrix as $key => $row) {
            foreach ($criteria as $criterion) {
                $denominator = $denominators[$criterion];
                $normalized = $denominator > 0 ? ($row[$criterion] ?? 0.0) / $denominator : 0.0;
                $weighted[$key][$criterion] = $normalized * $weights[$criterion];
            }
        }

        $idealBest = [];
        $idealWorst = [];
        foreach ($criteria as $criterion) {
            $values = array_column($weighted, $criterion);
            if ($isBenefit[$criterion] ?? true) {
                $idealBest[$criterion] = max($values);
                $idealWorst[$criterion] = min($values);
            } else {
                $idealBest[$criterion] = min($values);
                $idealWorst[$criterion] = max($values);
            }
        }

        $scores = [];
        foreach ($weighted as $key => $row) {
            $distanceToBest = 0.0;
            $distanceToWorst = 0.0;
            foreach ($criteria as $criterion) {
                $distanceToBest += ($row[$criterion] - $idealBest[$criterion]) ** 2;
                $distanceToWorst += ($row[$criterion] - $idealWorst[$criterion]) ** 2;
            }
            $distanceToBest = sqrt($distanceToBest);
            $distanceToWorst = sqrt($distanceToWorst);

            $denominator = $distanceToBest + $distanceToWorst;
            $scores[$key] = $denominator > 0 ? $distanceToWorst / $denominator : 0.0;
        }

        return $scores;
    }
}
