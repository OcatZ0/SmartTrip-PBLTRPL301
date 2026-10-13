<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\EncodedPolyline;
use PHPUnit\Framework\TestCase;

class EncodedPolylineTest extends TestCase
{
    public function test_it_matches_the_google_reference_example(): void
    {
        $encoded = EncodedPolyline::encode([
            ['lat' => 38.5, 'lng' => -120.2],
            ['lat' => 40.7, 'lng' => -120.95],
            ['lat' => 43.252, 'lng' => -126.453],
        ]);

        $this->assertSame('_p~iF~ps|U_ulLnnqC_mqNvxq`@', $encoded);
    }

    public function test_no_points_encode_to_an_empty_string(): void
    {
        $this->assertSame('', EncodedPolyline::encode([]));
    }
}
