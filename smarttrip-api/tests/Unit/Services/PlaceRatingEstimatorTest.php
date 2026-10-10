<?php

namespace Tests\Unit\Services;

use App\Models\Place;
use App\Services\Itinerary\PlaceRatingEstimator;
use Illuminate\Support\Collection;
use PHPUnit\Framework\TestCase;

class PlaceRatingEstimatorTest extends TestCase
{
    private function place(array $attributes): Place
    {
        return (new Place)->forceFill(array_merge(['type' => 'attraction', 'reviews_count' => 0, 'reviews_avg_rating' => null], $attributes));
    }

    public function test_tier_1_uses_the_rating_blend_when_present(): void
    {
        $place = $this->place(['rating' => 4.3]);

        $this->assertSame(4.3, (new PlaceRatingEstimator(new Collection))->estimate($place));
    }

    public function test_tier_2_uses_the_median_blend_of_the_same_type(): void
    {
        $pool = new Collection([
            $this->place(['rating' => 3.0]),
            $this->place(['rating' => 4.0]),
            $this->place(['rating' => 5.0]),
            $this->place(['rating' => 1.0, 'type' => 'culinary']),
        ]);
        $unrated = $this->place(['rating' => null]);

        $this->assertSame(4.0, (new PlaceRatingEstimator($pool))->estimate($unrated));
    }

    public function test_tier_3_falls_back_to_a_neutral_rating(): void
    {
        $pool = new Collection([$this->place(['rating' => null])]);
        $unrated = $this->place(['rating' => null]);

        $this->assertSame(PlaceRatingEstimator::NEUTRAL_FALLBACK, (new PlaceRatingEstimator($pool))->estimate($unrated));
    }
}
