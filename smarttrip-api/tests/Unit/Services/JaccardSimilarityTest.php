<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\JaccardSimilarity;
use PHPUnit\Framework\TestCase;

class JaccardSimilarityTest extends TestCase
{
    public function test_identical_sets_score_one(): void
    {
        $this->assertSame(1.0, JaccardSimilarity::of([1, 2, 3], [1, 2, 3]));
    }

    public function test_disjoint_sets_score_zero(): void
    {
        $this->assertSame(0.0, JaccardSimilarity::of([1, 2], [3, 4]));
    }

    public function test_partial_overlap(): void
    {
        // intersection {2,3} = 2, union {1,2,3,4} = 4 -> 0.5
        $this->assertSame(0.5, JaccardSimilarity::of([1, 2, 3], [2, 3, 4]));
    }

    public function test_both_empty_scores_zero_not_a_division_error(): void
    {
        $this->assertSame(0.0, JaccardSimilarity::of([], []));
    }

    public function test_one_empty_scores_zero(): void
    {
        $this->assertSame(0.0, JaccardSimilarity::of([], [1, 2]));
    }
}
