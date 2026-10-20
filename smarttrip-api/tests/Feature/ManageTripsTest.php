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

    // --- GET /api/trips: summary for the Trip Tersimpan card ---

    private function summaryPlace(string $name, ?string $photo, ?int $cost = null): Place
    {
        return Place::create([
            'name' => $name, 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.0, 'address' => 'Batam',
            'source' => 'manual', 'photo_url' => $photo, 'estimated_cost_idr' => $cost,
        ]);
    }

    /**
     * A trip with an itinerary: one stop per place, the first $visited marked visited.
     */
    private function tripWithStops(User $owner, string $startDate, array $places, int $visited = 0, int $numDays = 3): Trip
    {
        $trip = $this->makeTrip($owner, ['start_date' => $startDate, 'num_days' => $numDays]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        foreach ($places as $index => $place) {
            ItineraryItem::create([
                'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
                'visit_order' => $index + 1, 'source' => 'recommended',
                'visited_at' => $index < $visited ? now() : null,
            ]);
        }

        return $trip;
    }

    private function summaryOf(User $user, Trip $trip): array
    {
        $data = collect($this->withHeaders($this->authHeader($user))->getJson('/api/trips')->assertOk()->json('data'));

        return $data->firstWhere('trips_id', $trip->trips_id)['summary'];
    }

    public function test_a_trip_without_an_itinerary_is_a_draft_with_its_wishlist_photos(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $place = $this->summaryPlace('Pantai', 'https://example.com/pantai.jpg');
        $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);

        $summary = $this->summaryOf($user, $trip);

        $this->assertSame('draft', $summary['status']);
        $this->assertNull($summary['current_day']);
        $this->assertSame(0, $summary['places_count']);
        $this->assertSame(1, $summary['wishlist_count']);
        $this->assertSame(['https://example.com/pantai.jpg'], $summary['photo_urls']);
    }

    public function test_the_status_follows_the_trip_dates_in_batam_time(): void
    {
        $this->travelTo(\Illuminate\Support\Carbon::parse('2026-09-13 10:00', 'Asia/Jakarta'));
        $user = User::factory()->create();
        $place = $this->summaryPlace('Pantai', null);

        $upcoming = $this->tripWithStops($user, '2026-09-20', [$place]);
        $live = $this->tripWithStops($user, '2026-09-12', [$place]);
        $done = $this->tripWithStops($user, '2026-09-01', [$place]);

        $this->assertSame('akan_datang', $this->summaryOf($user, $upcoming)['status']);
        $this->assertSame('selesai', $this->summaryOf($user, $done)['status']);
        $liveSummary = $this->summaryOf($user, $live);
        $this->assertSame('berlangsung', $liveSummary['status']);
        // 12 Sep is day 1, so 13 Sep is day 2.
        $this->assertSame(2, $liveSummary['current_day']);
    }

    public function test_progress_spent_estimate_and_at_most_four_unique_photos(): void
    {
        $user = User::factory()->create();
        $places = [
            $this->summaryPlace('A', 'https://example.com/a.jpg', 10000),
            $this->summaryPlace('B', 'https://example.com/b.jpg', 25000),
            $this->summaryPlace('C', null, 50000),
            $this->summaryPlace('D', 'https://example.com/a.jpg'),
            $this->summaryPlace('E', 'https://example.com/e.jpg'),
            $this->summaryPlace('F', 'https://example.com/f.jpg'),
            $this->summaryPlace('G', 'https://example.com/g.jpg'),
        ];
        $trip = $this->tripWithStops($user, now()->addWeek()->toDateString(), $places, visited: 3);

        $summary = $this->summaryOf($user, $trip);

        $this->assertSame(7, $summary['places_count']);
        $this->assertSame(3, $summary['visited_count']);
        $this->assertSame(85000, $summary['spent_estimate_idr']);
        // Itinerary order, no empty or repeated photo, four at most.
        $this->assertSame([
            'https://example.com/a.jpg', 'https://example.com/b.jpg', 'https://example.com/e.jpg', 'https://example.com/f.jpg',
        ], $summary['photo_urls']);
    }

    public function test_the_list_does_not_carry_the_itinerary_itself(): void
    {
        $user = User::factory()->create();
        $this->tripWithStops($user, now()->addWeek()->toDateString(), [$this->summaryPlace('A', null)]);

        $trip = $this->withHeaders($this->authHeader($user))->getJson('/api/trips')->json('data.0');

        $this->assertArrayNotHasKey('days', $trip);
        $this->assertArrayNotHasKey('wishlist_places', $trip);
        $this->assertSame(1, $trip['days_count']);
    }
}
