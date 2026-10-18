<?php

namespace Tests\Unit\Services;

use App\Models\Place;
use App\Services\Itinerary\PlaceCostEstimator;
use Illuminate\Support\Collection;
use PHPUnit\Framework\TestCase;

class PlaceCostEstimatorTest extends TestCase
{
    private function place(array $attributes): Place
    {
        return (new Place)->forceFill(array_merge(['type' => 'attraction'], $attributes));
    }

    public function test_tier_1_uses_estimated_cost_idr_when_present(): void
    {
        $place = $this->place(['estimated_cost_idr' => 123000]);
        $estimator = new PlaceCostEstimator(new Collection);

        $this->assertSame(123000, $estimator->estimate($place));
    }

    public function test_tier_2_falls_back_to_median_of_same_type_places(): void
    {
        $place = $this->place(['estimated_cost_idr' => null]);

        $pool = new Collection([
            $this->place(['estimated_cost_idr' => 10000]),
            $this->place(['estimated_cost_idr' => 20000]),
            $this->place(['estimated_cost_idr' => 30000]),
            $this->place(['estimated_cost_idr' => null]),
            $this->place(['type' => 'lodging', 'estimated_cost_idr' => 900000]), // different type, excluded
        ]);

        $estimator = new PlaceCostEstimator($pool);

        $this->assertSame(20000.0, (float) $estimator->estimate($place));
    }

    public function test_tier_3_falls_back_to_the_hardcoded_default_per_type(): void
    {
        $attraction = $this->place(['type' => 'attraction', 'estimated_cost_idr' => null]);
        $lodging = $this->place(['type' => 'lodging', 'estimated_cost_idr' => null]);

        $estimator = new PlaceCostEstimator(new Collection);

        $this->assertSame(50000, $estimator->estimate($attraction));
        $this->assertSame(300000, $estimator->estimate($lodging));
    }
}
