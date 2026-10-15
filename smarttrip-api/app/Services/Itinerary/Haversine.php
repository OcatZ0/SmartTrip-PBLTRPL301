<?php

namespace App\Services\Itinerary;

/**
 * Jarak garis lurus antar koordinat (docs/prd design spec Section 7).
 */
class Haversine
{
    private const EARTH_RADIUS_KM = 6371.0;

    public static function km(float $lat1, float $lng1, float $lat2, float $lng2): float
    {
        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $haversineTerm = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLng / 2) ** 2;

        return self::EARTH_RADIUS_KM * 2 * atan2(sqrt($haversineTerm), sqrt(1 - $haversineTerm));
    }

    /**
     * Estimasi waktu tempuh kasar (menit) buat keputusan muat/tidak muat di
     * langkah 6b - jarak garis lurus x faktor detour, dibagi kecepatan
     * kota rata-rata. Bukan pengganti Routes API asli (langkah 6e).
     */
    public static function estimatedTravelMinutes(
        float $lat1,
        float $lng1,
        float $lat2,
        float $lng2,
        float $detourFactor = 1.35,
        float $averageSpeedKmh = 27.5
    ): float {
        $roadKm = self::km($lat1, $lng1, $lat2, $lng2) * $detourFactor;

        return ($roadKm / $averageSpeedKmh) * 60;
    }
}
