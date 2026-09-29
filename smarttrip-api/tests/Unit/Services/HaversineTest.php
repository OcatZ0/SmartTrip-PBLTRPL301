<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\Haversine;
use PHPUnit\Framework\TestCase;

class HaversineTest extends TestCase
{
    public function test_distance_between_identical_points_is_zero(): void
    {
        $this->assertSame(0.0, Haversine::km(1.15, 104.05, 1.15, 104.05));
    }

    public function test_one_degree_of_longitude_at_the_equator_is_about_111_km(): void
    {
        $km = Haversine::km(0, 0, 0, 1);

        $this->assertEqualsWithDelta(111.19, $km, 0.1);
    }

    public function test_one_degree_of_latitude_is_about_111_km(): void
    {
        $km = Haversine::km(0, 0, 1, 0);

        $this->assertEqualsWithDelta(111.19, $km, 0.1);
    }

    public function test_distance_is_symmetric(): void
    {
        $ab = Haversine::km(1.10, 104.00, 1.20, 104.10);
        $ba = Haversine::km(1.20, 104.10, 1.10, 104.00);

        $this->assertEqualsWithDelta($ab, $ba, 0.0001);
    }

    public function test_estimated_travel_minutes_applies_detour_and_speed(): void
    {
        // 1 deg longitude at equator (~111.19 km) x 1.35 detour / 27.5 km/h * 60.
        $minutes = Haversine::estimatedTravelMinutes(0, 0, 0, 1, 1.35, 27.5);

        $expectedKm = 111.19 * 1.35;
        $expectedMinutes = ($expectedKm / 27.5) * 60;

        $this->assertEqualsWithDelta($expectedMinutes, $minutes, 1.0);
    }
}
