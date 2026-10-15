<?php

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
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

    // --- F008: GET /api/trips/{id} ---

    public function test_the_trip_detail_includes_place_info_for_every_stop_and_the_hotel(): void
    {
        $user = User::factory()->create();
        $hotel = Place::create([
            'name' => 'Hotel Harbour Bay', 'type' => 'lodging', 'lat' => 1.16, 'lng' => 104.0,
            'address' => 'Batu Ampar', 'source' => 'google', 'external_place_id' => 'gp-hotel',
        ]);
        $trip = $this->makeTrip($user, ['hotel_places_id' => $hotel->places_id]);
        $place = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Barelang', 'source' => 'google', 'external_place_id' => 'gp-1',
            'estimated_visit_minutes' => 90, 'is_outdoor' => true,
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'source' => 'recommended',
        ]);

        $response = $this->withHeaders($this->authHeader($user))->getJson("/api/trips/{$trip->trips_id}");

        $response->assertOk();
        $this->assertSame('Pantai Melur', $response->json('days.0.items.0.place.name'));
        $this->assertSame(90, $response->json('days.0.items.0.place.estimated_visit_minutes'));
        $this->assertTrue($response->json('days.0.items.0.place.is_outdoor'));
        $this->assertSame('Hotel Harbour Bay', $response->json('hotel_place.name'));
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
        for ($number = 0; $number < 25; $number++) {
            $this->makeTrip($user, ['title' => "Trip $number"]);
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

    // --- F011: PATCH /api/trips/{id} (added after the 2026-10-10 PRD audit) ---

    public function test_the_owner_can_update_trip_fields(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->withHeaders($this->authHeader($user))->patchJson("/api/trips/{$trip->trips_id}", [
            'title' => 'Trip Baru', 'budget_total' => 750000, 'start_date' => '2026-12-24',
        ]);

        $response->assertOk();
        $response->assertJsonPath('title', 'Trip Baru');
        $response->assertJsonPath('itinerary_cleared', false);
        $this->assertDatabaseHas('trips', ['trips_id' => $trip->trips_id, 'title' => 'Trip Baru', 'budget_total' => 750000]);
    }

    public function test_a_non_owner_cannot_update_a_trip(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))->patchJson("/api/trips/{$trip->trips_id}", ['title' => 'X']);

        $response->assertForbidden();
    }

    public function test_a_viewer_cannot_update_a_trip(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))->patchJson("/api/trips/{$trip->trips_id}", ['title' => 'X']);

        $response->assertForbidden();
    }

    public function test_changing_num_days_clears_the_existing_itinerary(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = Place::create(['name' => 'Pantai', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.0, 'address' => 'Batam', 'source' => 'manual']);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        $item = ItineraryItem::create(['itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id, 'visit_order' => 1, 'source' => 'recommended']);

        $response = $this->withHeaders($this->authHeader($user))->patchJson("/api/trips/{$trip->trips_id}", ['num_days' => 3]);

        $response->assertOk();
        $response->assertJsonPath('itinerary_cleared', true);
        $response->assertJsonPath('num_days', 3);
        $this->assertDatabaseMissing('itinerary_days', ['trips_id' => $trip->trips_id]);
        $this->assertDatabaseMissing('itinerary_items', ['itinerary_items_id' => $item->itinerary_items_id]);
    }

    public function test_changing_only_the_title_or_start_date_keeps_the_itinerary(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);

        $response = $this->withHeaders($this->authHeader($user))->patchJson("/api/trips/{$trip->trips_id}", [
            'title' => 'Ganti Judul', 'start_date' => '2026-12-01',
        ]);

        $response->assertOk();
        $response->assertJsonPath('itinerary_cleared', false);
        $this->assertDatabaseHas('itinerary_days', ['trips_id' => $trip->trips_id, 'day_number' => 1]);
    }

    public function test_daily_end_time_must_stay_after_daily_start_time_when_updating(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->withHeaders($this->authHeader($user))->patchJson("/api/trips/{$trip->trips_id}", ['daily_end_time' => '08:00']);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors('daily_end_time');
    }
}
