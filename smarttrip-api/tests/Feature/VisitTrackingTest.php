<?php

namespace Tests\Feature;

use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class VisitTrackingTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function tripWithOneItem(User $owner): array
    {
        $trip = Trip::create([
            'users_id' => $owner->users_id, 'title' => 'Trip', 'num_days' => 1,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);
        $place = Place::create([
            'name' => 'Tempat', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
            'estimated_visit_minutes' => 60,
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        $item = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'topsis_score' => 0.8, 'source' => 'wishlist',
        ]);

        return compact('trip', 'day', 'item');
    }

    public function test_the_owner_can_mark_a_stop_as_visited(): void
    {
        $user = User::factory()->create();
        ['item' => $item] = $this->tripWithOneItem($user);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/itinerary-items/{$item->itinerary_items_id}/visit");

        $response->assertOk();
        $this->assertNotNull($item->fresh()->visited_at);
        $this->assertNotNull($response->json('visited_at'));
    }

    public function test_marking_an_already_visited_stop_again_toggles_it_back_to_unvisited(): void
    {
        $user = User::factory()->create();
        ['item' => $item] = $this->tripWithOneItem($user);
        $item->update(['visited_at' => now()]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/itinerary-items/{$item->itinerary_items_id}/visit");

        $response->assertOk();
        $this->assertNull($item->fresh()->visited_at);
        $this->assertNull($response->json('visited_at'));
    }

    public function test_a_non_owner_cannot_mark_a_stop_as_visited(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        ['item' => $item] = $this->tripWithOneItem($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->postJson("/api/itinerary-items/{$item->itinerary_items_id}/visit");

        $response->assertForbidden();
        $this->assertNull($item->fresh()->visited_at);
    }

    public function test_a_viewer_cannot_mark_a_stop_as_visited(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        ['trip' => $trip, 'item' => $item] = $this->tripWithOneItem($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))
            ->postJson("/api/itinerary-items/{$item->itinerary_items_id}/visit");

        $response->assertForbidden();
        $this->assertNull($item->fresh()->visited_at);
    }

    public function test_marking_a_visit_requires_authentication(): void
    {
        ['item' => $item] = $this->tripWithOneItem(User::factory()->create());

        $response = $this->postJson("/api/itinerary-items/{$item->itinerary_items_id}/visit");

        $response->assertUnauthorized();
    }

    public function test_a_viewer_can_see_visited_at_through_the_trip_detail_endpoint(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        ['trip' => $trip, 'item' => $item] = $this->tripWithOneItem($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);
        $item->update(['visited_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))
            ->getJson("/api/trips/{$trip->trips_id}");

        $response->assertOk();
        $this->assertNotNull($response->json('days.0.items.0.visited_at'));
    }
}
