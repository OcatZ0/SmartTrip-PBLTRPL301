<?php

namespace App\Services\Itinerary;

/**
 * Urutan kunjungan per hari (docs/prd design spec Section 7 langkah 6d) -
 * mulai dari titik awal (hotel), greedy pilih stop terdekat berikutnya,
 * sampai semua stop terkunjungi.
 */
class NearestNeighborRoute
{
    /**
     * @param  array{lat: float, lng: float}  $start
     * @param  array<int|string, array{lat: float, lng: float}>  $stops  keyed bebas (mis. array index sementara/id stop)
     * @return array<int, int|string> urutan key stop, dari yang pertama dikunjungi
     */
    public static function order(array $start, array $stops): array
    {
        $remaining = $stops;
        $order = [];
        $current = $start;

        while ($remaining !== []) {
            $nearestKey = null;
            $nearestDistance = null;

            foreach ($remaining as $key => $stop) {
                $distance = Haversine::km($current['lat'], $current['lng'], $stop['lat'], $stop['lng']);
                if ($nearestDistance === null || $distance < $nearestDistance) {
                    $nearestDistance = $distance;
                    $nearestKey = $key;
                }
            }

            $order[] = $nearestKey;
            $current = $remaining[$nearestKey];
            unset($remaining[$nearestKey]);
        }

        return $order;
    }
}
