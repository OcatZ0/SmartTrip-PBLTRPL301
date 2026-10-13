<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\Trip;
use App\Models\TripViewer;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class WishlistTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function makeTrip(User $owner): Trip
    {
        return Trip::create([
            'users_id' => $owner->users_id, 'title' => 'Trip', 'num_days' => 3,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);
    }

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
            'estimated_visit_minutes' => 90,
        ], $overrides));
    }

    // --- create trip (prerequisite scaffolding) ---

    public function test_an_authenticated_user_can_create_a_trip(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeader($user))->postJson('/api/trips', [
            'num_days' => 3, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);

        $response->assertCreated();
        $this->assertDatabaseHas('trips', ['users_id' => $user->users_id, 'num_days' => 3]);
    }

    public function test_creating_a_trip_requires_authentication(): void
    {
        $response = $this->postJson('/api/trips', [
            'num_days' => 3, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);

        $response->assertUnauthorized();
    }

    // --- F007: wishlist ---

    public function test_the_owner_can_add_a_catalog_place_to_the_wishlist(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", ['places_id' => $place->places_id]);

        $response->assertCreated();
        $response->assertJsonPath('data.source', 'catalog');
        $response->assertJsonPath('data.place.places_id', $place->places_id);
        $this->assertDatabaseHas('trip_wishlist_places', [
            'trips_id' => $trip->trips_id, 'places_id' => $place->places_id,
        ]);
    }

    public function test_adding_the_same_place_twice_is_a_no_op(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = $this->makePlace();
        $headers = $this->authHeader($user);

        $first = $this->withHeaders($headers)
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", ['places_id' => $place->places_id]);
        $first->assertCreated();

        $second = $this->withHeaders($headers)
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", ['places_id' => $place->places_id]);
        $second->assertOk();

        $this->assertSame(1, $trip->wishlistPlaces()->count());
        $this->assertSame($first->json('data.trip_wishlist_places_id'), $second->json('data.trip_wishlist_places_id'));
    }

    public function test_the_owner_can_add_a_custom_pin_to_the_wishlist(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", [
                'custom_name' => 'Spot Foto Pribadi', 'custom_lat' => 1.16, 'custom_lng' => 104.08,
                'custom_visit_minutes' => 30,
            ]);

        $response->assertCreated();
        $response->assertJsonPath('data.source', 'custom');
        $response->assertJsonPath('data.custom_name', 'Spot Foto Pribadi');
        $response->assertJsonPath('data.place', null);
    }

    public function test_a_custom_pin_requires_visit_minutes(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", [
                'custom_name' => 'Spot Foto', 'custom_lat' => 1.16, 'custom_lng' => 104.08,
            ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['custom_visit_minutes']);
    }

    public function test_places_id_and_custom_fields_are_mutually_exclusive(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", [
                'places_id' => $place->places_id, 'custom_name' => 'Tidak boleh dua-duanya',
            ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['custom_name']);
    }

    public function test_a_non_owner_cannot_add_to_the_wishlist(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($stranger))
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", ['places_id' => $place->places_id]);

        $response->assertForbidden();
    }

    public function test_the_owner_can_list_the_wishlist(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = $this->makePlace();
        $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);
        $trip->wishlistPlaces()->create([
            'custom_name' => 'Pin Custom', 'custom_lat' => 1.1, 'custom_lng' => 104.0, 'custom_visit_minutes' => 20,
        ]);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/trips/{$trip->trips_id}/wishlist");

        $response->assertOk();
        $this->assertCount(2, $response->json('data'));
    }

    public function test_a_viewer_can_list_the_wishlist(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        TripViewer::create(['trips_id' => $trip->trips_id, 'users_id' => $viewer->users_id, 'added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))
            ->getJson("/api/trips/{$trip->trips_id}/wishlist");

        $response->assertOk();
    }

    public function test_a_stranger_cannot_list_the_wishlist(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->getJson("/api/trips/{$trip->trips_id}/wishlist");

        $response->assertForbidden();
    }

    public function test_a_viewer_cannot_write_to_the_wishlist(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $place = $this->makePlace();
        TripViewer::create(['trips_id' => $trip->trips_id, 'users_id' => $viewer->users_id, 'added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))
            ->postJson("/api/trips/{$trip->trips_id}/wishlist", ['places_id' => $place->places_id]);

        $response->assertForbidden();
    }

    public function test_the_owner_can_delete_a_wishlist_item(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = $this->makePlace();
        $item = $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);

        $response = $this->withHeaders($this->authHeader($user))
            ->deleteJson("/api/trips/{$trip->trips_id}/wishlist/{$item->trip_wishlist_places_id}");

        $response->assertOk();
        $this->assertDatabaseMissing('trip_wishlist_places', ['trip_wishlist_places_id' => $item->trip_wishlist_places_id]);
    }

    public function test_a_non_owner_cannot_delete_a_wishlist_item(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $place = $this->makePlace();
        $item = $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->deleteJson("/api/trips/{$trip->trips_id}/wishlist/{$item->trip_wishlist_places_id}");

        $response->assertForbidden();
        $this->assertDatabaseHas('trip_wishlist_places', ['trip_wishlist_places_id' => $item->trip_wishlist_places_id]);
    }

    public function test_a_wishlist_item_from_a_different_trip_404s(): void
    {
        $user = User::factory()->create();
        $tripA = $this->makeTrip($user);
        $tripB = $this->makeTrip($user);
        $place = $this->makePlace();
        $item = $tripA->wishlistPlaces()->create(['places_id' => $place->places_id]);

        $response = $this->withHeaders($this->authHeader($user))
            ->deleteJson("/api/trips/{$tripB->trips_id}/wishlist/{$item->trip_wishlist_places_id}");

        $response->assertNotFound();
    }
}
