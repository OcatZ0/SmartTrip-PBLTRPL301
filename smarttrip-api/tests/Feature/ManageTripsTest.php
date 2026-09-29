<?php

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ManageTripsTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function makeTrip(User $owner, array $overrides = []): Trip
    {
        return Trip::create(array_merge([
            'users_id' => $owner->users_id, 'title' => 'Trip', 'num_days' => 2,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ], $overrides));
    }

    // --- F011: GET /api/trips ---

    public function test_a_user_can_list_their_own_trips(): void
    {
        $user = User::factory()->create();
        $this->makeTrip($user, ['title' => 'Trip Pertama']);
        $this->makeTrip($user, ['title' => 'Trip Kedua']);

        $response = $this->withHeaders($this->authHeader($user))->getJson('/api/trips');

        $response->assertOk();
        $this->assertCount(2, $response->json('data'));
    }

    public function test_listing_trips_requires_authentication(): void
    {
        $response = $this->getJson('/api/trips');

        $response->assertUnauthorized();
    }

    public function test_a_user_only_sees_their_own_trips_not_others(): void
    {
        $userA = User::factory()->create();
        $userB = User::factory()->create();
        $this->makeTrip($userA, ['title' => 'Trip A']);
        $this->makeTrip($userB, ['title' => 'Trip B']);

        $response = $this->withHeaders($this->authHeader($userA))->getJson('/api/trips');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Trip A', $response->json('data.0.title'));
    }

    public function test_trips_shared_as_a_viewer_do_not_appear_in_my_own_trip_list(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))->getJson('/api/trips');

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    public function test_a_deleted_trip_no_longer_appears_in_the_list(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $trip->delete();

        $response = $this->withHeaders($this->authHeader($user))->getJson('/api/trips');

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    public function test_trip_list_is_paginated(): void
    {
        $user = User::factory()->create();
        for ($i = 0; $i < 25; $i++) {
            $this->makeTrip($user, ['title' => "Trip $i"]);
        }

        $response = $this->withHeaders($this->authHeader($user))->getJson('/api/trips?per_page=10');

        $response->assertOk();
        $this->assertCount(10, $response->json('data'));
        $this->assertSame(25, $response->json('total'));
    }

    // --- F011: DELETE /api/trips/{id} ---

    public function test_the_owner_can_delete_their_trip(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->withHeaders($this->authHeader($user))->deleteJson("/api/trips/{$trip->trips_id}");

        $response->assertOk();
        $this->assertSoftDeleted($trip);
    }

    public function test_a_deleted_trip_cannot_be_fetched_afterward(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $headers = $this->authHeader($user);

        $this->withHeaders($headers)->deleteJson("/api/trips/{$trip->trips_id}")->assertOk();

        $response = $this->withHeaders($headers)->getJson("/api/trips/{$trip->trips_id}");

        $response->assertNotFound();
    }

    public function test_a_non_owner_cannot_delete_a_trip(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))->deleteJson("/api/trips/{$trip->trips_id}");

        $response->assertForbidden();
        $this->assertDatabaseHas('trips', ['trips_id' => $trip->trips_id, 'deleted_at' => null]);
    }

    public function test_a_viewer_cannot_delete_a_trip(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))->deleteJson("/api/trips/{$trip->trips_id}");

        $response->assertForbidden();
    }

    public function test_deleting_a_trip_requires_authentication(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->deleteJson("/api/trips/{$trip->trips_id}");

        $response->assertUnauthorized();
    }
}
