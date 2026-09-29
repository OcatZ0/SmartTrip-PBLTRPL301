<?php

namespace Tests\Unit\Services;

use App\Services\Itinerary\NearestNeighborRoute;
use PHPUnit\Framework\TestCase;

class NearestNeighborRouteTest extends TestCase
{
    public function test_it_visits_stops_nearest_first(): void
    {
        $start = ['lat' => 0.0, 'lng' => 0.0];
        $stops = [
            'far' => ['lat' => 0.0, 'lng' => 10.0],
            'near' => ['lat' => 0.0, 'lng' => 1.0],
            'mid' => ['lat' => 0.0, 'lng' => 5.0],
        ];

        $order = NearestNeighborRoute::order($start, $stops);

        $this->assertSame(['near', 'mid', 'far'], $order);
    }

    public function test_it_greedily_chains_from_the_last_visited_stop(): void
    {
        // Start at 0. "left" is close to start, but once there, "leftmost"
        // is nearer than "right" - greedy NN should go start->left->leftmost->right,
        // not the globally shortest path.
        $start = ['lat' => 0.0, 'lng' => 0.0];
        $stops = [
            'left' => ['lat' => 0.0, 'lng' => -1.0],
            'leftmost' => ['lat' => 0.0, 'lng' => -2.0],
            'right' => ['lat' => 0.0, 'lng' => 5.0],
        ];

        $order = NearestNeighborRoute::order($start, $stops);

        $this->assertSame(['left', 'leftmost', 'right'], $order);
    }

    public function test_empty_stops_returns_empty_order(): void
    {
        $this->assertSame([], NearestNeighborRoute::order(['lat' => 0.0, 'lng' => 0.0], []));
    }

    public function test_a_single_stop(): void
    {
        $order = NearestNeighborRoute::order(['lat' => 0.0, 'lng' => 0.0], ['only' => ['lat' => 1.0, 'lng' => 1.0]]);

        $this->assertSame(['only'], $order);
    }
}
