<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\KMeans;
use PHPUnit\Framework\TestCase;

class KMeansTest extends TestCase
{
    public function test_it_separates_two_clearly_distinct_groups(): void
    {
        $points = [
            ['lat' => 1.10, 'lng' => 104.00], // group A
            ['lat' => 1.11, 'lng' => 104.01], // group A
            ['lat' => 1.12, 'lng' => 104.00], // group A
            ['lat' => 1.50, 'lng' => 104.50], // group B
            ['lat' => 1.51, 'lng' => 104.51], // group B
            ['lat' => 1.52, 'lng' => 104.50], // group B
        ];

        $assignments = KMeans::cluster($points, 2);

        $this->assertCount(6, $assignments);
        $this->assertSame($assignments[0], $assignments[1]);
        $this->assertSame($assignments[1], $assignments[2]);
        $this->assertSame($assignments[3], $assignments[4]);
        $this->assertSame($assignments[4], $assignments[5]);
        $this->assertNotSame($assignments[0], $assignments[3]);
    }

    public function test_k_greater_than_point_count_is_capped(): void
    {
        $points = [
            ['lat' => 1.10, 'lng' => 104.00],
            ['lat' => 1.11, 'lng' => 104.01],
        ];

        $assignments = KMeans::cluster($points, 5);

        $this->assertCount(2, $assignments);
        $uniqueClusters = array_unique($assignments);
        $this->assertLessThanOrEqual(2, count($uniqueClusters));
    }

    public function test_k_of_one_puts_everything_in_one_cluster(): void
    {
        $points = [
            ['lat' => 1.10, 'lng' => 104.00],
            ['lat' => 1.50, 'lng' => 104.50],
        ];

        $assignments = KMeans::cluster($points, 1);

        $this->assertSame([0, 0], $assignments);
    }

    public function test_empty_points_returns_empty_assignments(): void
    {
        $this->assertSame([], KMeans::cluster([], 3));
    }

    public function test_centroid_is_the_average_coordinate(): void
    {
        $centroid = KMeans::centroid([
            ['lat' => 1.0, 'lng' => 104.0],
            ['lat' => 2.0, 'lng' => 106.0],
        ]);

        $this->assertSame(1.5, $centroid['lat']);
        $this->assertSame(105.0, $centroid['lng']);
    }
}
