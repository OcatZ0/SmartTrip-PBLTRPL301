<?php

namespace App\Services\Itinerary;

/**
 * Google encoded polyline format (precision 5). itinerary_items.polyline_to_here
 * keeps this format whatever the routing provider is, so the mobile decoder
 * does not change.
 */
class EncodedPolyline
{
    /**
     * @param  array<int, array{lat: float, lng: float}>  $points
     */
    public static function encode(array $points): string
    {
        $encoded = '';
        $previousLat = 0;
        $previousLng = 0;

        foreach ($points as $point) {
            $lat = (int) round($point['lat'] * 1e5);
            $lng = (int) round($point['lng'] * 1e5);

            $encoded .= self::encodeValue($lat - $previousLat).self::encodeValue($lng - $previousLng);

            $previousLat = $lat;
            $previousLng = $lng;
        }

        return $encoded;
    }

    private static function encodeValue(int $value): string
    {
        $value = $value < 0 ? ~($value << 1) : $value << 1;
        $chunks = '';

        while ($value >= 0x20) {
            $chunks .= chr((0x20 | ($value & 0x1f)) + 63);
            $value >>= 5;
        }

        return $chunks.chr($value + 63);
    }
}
