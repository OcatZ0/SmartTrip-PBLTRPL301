<?php

namespace Tests\Feature;

use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SharedItineraryTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function makeTrip(User $owner, array $overrides = []): Trip
    {
        return Trip::create(array_merge([
            'users_id' => $owner->users_id, 'title' => 'Trip Batam', 'num_days' => 2,
            'budget_total' => 5000000, 'start_date' => now()->addWeek()->toDateString(),
        ], $overrides));
    }

    // --- POST /api/trips/{id}/share-link ---

    public function test_the_owner_can_generate_a_share_link_token(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))
            ->postJson("/api/trips/{$trip->trips_id}/share-link");

        $response->assertOk();
        $this->assertNotNull($response->json('share_token'));
        $this->assertSame($trip->fresh()->share_token, $response->json('share_token'));
    }

    public function test_generating_a_share_link_twice_returns_the_same_token(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $headers = $this->authHeader($owner);

        $first = $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/share-link")->json('share_token');
        $second = $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/share-link")->json('share_token');

        $this->assertSame($first, $second);
    }

    public function test_a_non_owner_cannot_generate_a_share_link(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->postJson("/api/trips/{$trip->trips_id}/share-link");

        $response->assertForbidden();
    }

    // --- DELETE /api/trips/{id}/share-link ---

    public function test_the_owner_can_disable_the_share_link(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['share_token' => 'oldtoken']);

        $response = $this->withHeaders($this->authHeader($owner))
            ->deleteJson("/api/trips/{$trip->trips_id}/share-link");

        $response->assertOk();
        $this->assertNull($trip->fresh()->share_token);
    }

    public function test_disabling_the_share_link_immediately_breaks_the_old_link(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['share_token' => 'oldtoken']);

        $this->withHeaders($this->authHeader($owner))
            ->deleteJson("/api/trips/{$trip->trips_id}/share-link")
            ->assertOk();

        $response = $this->getJson('/api/shared-itinerary/oldtoken');

        $response->assertNotFound();
    }

    public function test_a_non_owner_cannot_disable_the_share_link(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner, ['share_token' => 'oldtoken']);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->deleteJson("/api/trips/{$trip->trips_id}/share-link");

        $response->assertForbidden();
        $this->assertSame('oldtoken', $trip->fresh()->share_token);
    }

    // --- GET /api/shared-itinerary/{token} (public, anon) ---

    public function test_the_shared_itinerary_is_publicly_readable_without_authentication(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['share_token' => 'publictoken', 'title' => 'Liburan Batam']);
        $place = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
            'estimated_visit_minutes' => 60, 'photo_url' => 'foto.jpg',
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'source' => 'wishlist', 'polyline_to_here' => 'poly123',
        ]);

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $response->assertJsonPath('title', 'Liburan Batam');
        $response->assertJsonPath('days.0.items.0.name', 'Pantai Melur');
        $response->assertJsonPath('days.0.items.0.polyline_to_here', 'poly123');
        $response->assertJsonPath('days.0.items.0.estimated_visit_minutes', 60);
    }

    public function test_a_missing_or_invalid_token_404s(): void
    {
        $response = $this->getJson('/api/shared-itinerary/does-not-exist');

        $response->assertNotFound();
    }

    public function test_the_public_response_never_leaks_visited_at_owner_identity_or_budget(): void
    {
        $owner = User::factory()->create(['name' => 'Rahasia Pemilik', 'email' => 'rahasia@test.com']);
        $trip = $this->makeTrip($owner, ['share_token' => 'publictoken', 'budget_total' => 9999999]);
        $place = Place::create([
            'name' => 'Pantai', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'source' => 'wishlist', 'visited_at' => now(),
        ]);

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $raw = $response->getContent();
        $this->assertStringNotContainsString('visited_at', $raw);
        $this->assertStringNotContainsString('budget_total', $raw);
        $this->assertStringNotContainsString('9999999', $raw);
        $this->assertStringNotContainsString('Rahasia Pemilik', $raw);
        $this->assertStringNotContainsString('rahasia@test.com', $raw);
        $this->assertStringNotContainsString('users_id', $raw);
    }

    public function test_a_custom_pin_hotel_location_is_hidden_behind_a_generic_label(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, [
            'share_token' => 'publictoken',
            'hotel_custom_name' => 'Rumah Kerabat Jl. Rahasia No 5',
            'hotel_lat' => 1.234567,
            'hotel_lng' => 104.987654,
        ]);

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $response->assertJsonPath('hotel.type', 'custom');
        $response->assertJsonPath('hotel.label', 'Hotel');
        $raw = $response->getContent();
        $this->assertStringNotContainsString('Rumah Kerabat', $raw);
        $this->assertStringNotContainsString('1.234567', $raw);
        $this->assertStringNotContainsString('104.987654', $raw);
    }

    public function test_a_catalog_hotel_location_is_shown_as_is(): void
    {
        $owner = User::factory()->create();
        $hotel = Place::create([
            'name' => 'Hotel Harmoni', 'type' => 'lodging', 'lat' => 1.13, 'lng' => 104.03,
            'address' => 'Batam Kota', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
        ]);
        $trip = $this->makeTrip($owner, ['share_token' => 'publictoken', 'hotel_places_id' => $hotel->places_id]);

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $response->assertJsonPath('hotel.type', 'catalog');
        $response->assertJsonPath('hotel.name', 'Hotel Harmoni');
        $response->assertJsonPath('hotel.lat', 1.13);
    }

    public function test_a_trip_with_no_hotel_set_yet_returns_a_null_hotel(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['share_token' => 'publictoken']);

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $this->assertNull($response->json('hotel'));
    }

    public function test_the_public_endpoint_only_exposes_the_one_trip_matching_the_token(): void
    {
        $owner = User::factory()->create();
        $this->makeTrip($owner, ['share_token' => 'publictoken', 'title' => 'Trip Publik']);
        $this->makeTrip($owner, ['share_token' => null, 'title' => 'Trip Privat']);

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $response->assertJsonPath('title', 'Trip Publik');
        $raw = $response->getContent();
        $this->assertStringNotContainsString('Trip Privat', $raw);
    }

    public function test_a_soft_deleted_place_still_appears_in_the_public_itinerary(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['share_token' => 'publictoken']);
        $place = Place::create([
            'name' => 'Pantai Lama', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'manual',
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'source' => 'wishlist',
        ]);
        $place->delete();

        $response = $this->getJson('/api/shared-itinerary/publictoken');

        $response->assertOk();
        $response->assertJsonPath('days.0.items.0.name', 'Pantai Lama');
    }
}
