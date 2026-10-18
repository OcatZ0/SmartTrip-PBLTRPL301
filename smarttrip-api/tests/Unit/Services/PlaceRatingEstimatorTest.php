<?php

namespace Tests\Unit\Services;

use App\Models\Place;
use App\Services\Itinerary\PlaceRatingEstimator;
use Illuminate\Support\Collection;
use PHPUnit\Framework\TestCase;

class PlaceRatingEstimatorTest extends TestCase
{
    private function place(?float $averageRating, array $attributes = []): Place
    {
        return (new Place)->forceFill(array_merge([
            'type' => 'attraction',
            'reviews_count' => $averageRating === null ? 0 : 3,
            'reviews_avg_rating' => $averageRating,
        ], $attributes));
    }

    public function test_tier_1_uses_the_in_app_review_average(): void
    {
        $this->assertSame(4.3, (new PlaceRatingEstimator(new Collection))->estimate($this->place(4.3)));
    }

    public function test_tier_2_uses_the_median_rating_of_the_same_type(): void
    {
        $pool = new Collection([
            $this->place(3.0),
            $this->place(4.0),
            $this->place(5.0),
            $this->place(1.0, ['type' => 'culinary']),
        ]);

        $this->assertSame(4.0, (new PlaceRatingEstimator($pool))->estimate($this->place(null)));
    }

    public function test_tier_3_falls_back_to_a_neutral_rating(): void
    {
        $pool = new Collection([$this->place(null)]);

        $this->assertSame(PlaceRatingEstimator::NEUTRAL_FALLBACK, (new PlaceRatingEstimator($pool))->estimate($this->place(null)));
    }
}
