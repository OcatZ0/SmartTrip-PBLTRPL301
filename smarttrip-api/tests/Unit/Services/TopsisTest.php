<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\Topsis;
use PHPUnit\Framework\TestCase;

class TopsisTest extends TestCase
{
    public function test_it_ranks_the_dominant_alternative_highest(): void
    {
        // A is better on both criteria than B on every axis - A must win outright.
        $matrix = [
            'A' => ['rating' => 5.0, 'distance' => 1.0],
            'B' => ['rating' => 2.0, 'distance' => 10.0],
        ];
        $weights = ['rating' => 0.5, 'distance' => 0.5];
        $isBenefit = ['rating' => true, 'distance' => false];

        $scores = Topsis::rank($matrix, $weights, $isBenefit);

        $this->assertGreaterThan($scores['B'], $scores['A']);
        $this->assertEqualsWithDelta(1.0, $scores['A'], 0.0001);
        $this->assertEqualsWithDelta(0.0, $scores['B'], 0.0001);
    }

    public function test_identical_alternatives_score_equally(): void
    {
        $matrix = [
            'A' => ['rating' => 4.0, 'distance' => 2.0],
            'B' => ['rating' => 4.0, 'distance' => 2.0],
        ];
        $weights = ['rating' => 0.5, 'distance' => 0.5];
        $isBenefit = ['rating' => true, 'distance' => false];

        $scores = Topsis::rank($matrix, $weights, $isBenefit);

        $this->assertEqualsWithDelta($scores['A'], $scores['B'], 0.0001);
    }

    public function test_scores_stay_within_zero_and_one(): void
    {
        $matrix = [
            'A' => ['rating' => 4.5, 'distance' => 3.0, 'budget' => 100000],
            'B' => ['rating' => 3.0, 'distance' => 1.0, 'budget' => 50000],
            'C' => ['rating' => 5.0, 'distance' => 8.0, 'budget' => 300000],
        ];
        $weights = ['rating' => 0.4, 'distance' => 0.3, 'budget' => 0.3];
        $isBenefit = ['rating' => true, 'distance' => false, 'budget' => false];

        $scores = Topsis::rank($matrix, $weights, $isBenefit);

        foreach ($scores as $score) {
            $this->assertGreaterThanOrEqual(0.0, $score);
            $this->assertLessThanOrEqual(1.0, $score);
        }
    }

    public function test_empty_matrix_returns_empty_scores(): void
    {
        $this->assertSame([], Topsis::rank([], ['rating' => 1.0], ['rating' => true]));
    }

    public function test_a_single_alternative_does_not_error(): void
    {
        $matrix = ['A' => ['rating' => 4.0]];
        $scores = Topsis::rank($matrix, ['rating' => 1.0], ['rating' => true]);

        $this->assertArrayHasKey('A', $scores);
        $this->assertIsFloat($scores['A']);
    }
}
