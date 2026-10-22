<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceReview;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class ItineraryGenerationTest extends TestCase
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
            'budget_total' => 1000000, 'start_date' => now()->addWeek()->toDateString(),
        ], $overrides));
    }

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Tempat', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
            'estimated_visit_minutes' => 60,
        ], $overrides));
    }

    /**
     * OpenRouteService dipalsukan: respons menyesuaikan jumlah waypoint
     * yang dikirim, 10 menit tiap leg.
     */
    private function fakeRoutes(): void
    {
        Http::fake([
            'api.openrouteservice.org/*' => fn ($request) => Http::response(self::orsRoute(count($request['coordinates']))),
        ]);
    }

    /**
     * OpenRouteService GeoJSON response for any number of waypoints: every
     * leg takes 10 minutes and is a straight two-point line.
     */
    private static function orsRoute(int $waypointCount): array
    {
        $coordinates = [];
        for ($waypoint = 0; $waypoint < $waypointCount; $waypoint++) {
            $coordinates[] = [104.0 + $waypoint / 100, 1.1 + $waypoint / 100];
        }

        return ['features' => [[
            'geometry' => ['type' => 'LineString', 'coordinates' => $coordinates],
            'properties' => [
                'segments' => array_fill(0, max($waypointCount - 1, 0), ['duration' => 600.0, 'distance' => 5000.0]),
                'way_points' => range(0, $waypointCount - 1),
            ],
        ]]];
    }

    // --- weights ---

    public function test_weights_normalizes_ratings_and_stores_interest_categories(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/weights", [
            'category_ids' => [$beach->categories_id, $culinary->categories_id],
            'rating_kategori' => 8, 'rating_jarak' => 4, 'rating_anggaran' => 4, 'rating_rating' => 4,
        ]);

        $response->assertOk();
        $trip->refresh();
        $this->assertEqualsWithDelta(0.4, (float) $trip->weight_kategori, 0.001);
        $this->assertEqualsWithDelta(0.2, (float) $trip->weight_jarak, 0.001);
        $this->assertCount(2, $trip->interestCategories);
    }

    public function test_weights_defaults_to_equal_shares_when_all_ratings_are_zero(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/weights", [
            'category_ids' => [$category->categories_id],
            'rating_kategori' => 0, 'rating_jarak' => 0, 'rating_anggaran' => 0, 'rating_rating' => 0,
        ]);

        $response->assertOk();
        $trip->refresh();
        $this->assertEqualsWithDelta(0.25, (float) $trip->weight_kategori, 0.001);
        $this->assertEqualsWithDelta(0.25, (float) $trip->weight_rating, 0.001);
    }

    // --- hotel ---

    public function test_hotel_can_be_set_from_the_catalog(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $hotel = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Batam']);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/hotel", ['places_id' => $hotel->places_id]);

        $response->assertOk();
        // Simple mode: every day starts at the hotel.
        $this->assertSame([$hotel->places_id], $trip->days()->pluck('start_places_id')->unique()->values()->all());
        $this->assertSame($trip->num_days, $trip->days()->count());
    }

    public function test_hotel_can_be_set_as_a_custom_pin(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/hotel", [
                'custom_name' => 'Rumah Saudara', 'custom_lat' => 1.13, 'custom_lng' => 104.03,
            ]);

        $response->assertOk();
        $day = $trip->days()->orderBy('day_number')->first();
        $this->assertNull($day->start_places_id);
        $this->assertSame('Rumah Saudara', $day->start_custom_name);
        $this->assertSame('Rumah Saudara', $response->json('days.0.start.name'));
    }

    public function test_hotel_options_ranks_lodgings_by_topsis(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $trip->update(['weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25]);

        // Near + cheap should clearly outrank far + expensive.
        $this->makePlace([
            'type' => 'lodging', 'name' => 'Hotel Dekat', 'lat' => 1.150, 'lng' => 104.050,
            'estimated_cost_idr' => 100000,
        ]);
        $this->makePlace([
            'type' => 'lodging', 'name' => 'Hotel Jauh', 'lat' => 1.500, 'lng' => 104.500,
            'estimated_cost_idr' => 900000, 'external_place_id' => 'gp-far',
        ]);
        $this->makePlace([
            'type' => 'attraction', 'name' => 'Wishlist Anchor', 'lat' => 1.151, 'lng' => 104.051,
            'external_place_id' => 'gp-anchor',
        ]);
        $anchor = Place::where('name', 'Wishlist Anchor')->first();
        $trip->wishlistPlaces()->create(['places_id' => $anchor->places_id]);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/trips/{$trip->trips_id}/hotel-options");

        $response->assertOk();
        $this->assertSame('Hotel Dekat', $response->json('data.0.name'));
    }

    public function test_hotel_options_without_a_wishlist_center_on_the_best_rated_places(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $near = $this->makePlace(['type' => 'attraction', 'name' => 'Disukai', 'lat' => 1.150, 'lng' => 104.050, 'external_place_id' => 'gp-liked']);
        PlaceReview::create(['places_id' => $near->places_id, 'users_id' => $user->users_id, 'rating' => 5]);
        $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Dekat', 'lat' => 1.151, 'lng' => 104.051, 'external_place_id' => 'gp-h1']);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/trips/{$trip->trips_id}/hotel-options");

        $response->assertOk();
        $this->assertSame('Hotel Dekat', $response->json('data.0.name'));
    }

    public function test_hotel_options_is_empty_when_trip_has_own_hotel(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user, ['has_own_hotel' => true]);
        $this->makePlace(['type' => 'lodging']);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/trips/{$trip->trips_id}/hotel-options");

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    // --- generate: preconditions ---

    public function test_generate_requires_weights_to_be_set_first(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $hotel = $this->makePlace(['type' => 'lodging']);
        $this->setTripStart($trip, ['start_places_id' => $hotel->places_id]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertUnprocessable();
    }

    public function test_generate_requires_a_hotel_to_be_set_first(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $trip->interestCategories()->attach($category->categories_id);
        $trip->update(['weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertUnprocessable();
    }

    public function test_a_non_owner_cannot_generate(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertForbidden();
    }

    // --- generate: full pipeline ---

    private function readyTrip(User $user, int $numDays = 2): Trip
    {
        $trip = $this->makeTrip($user, ['num_days' => $numDays]);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $hotel = $this->makePlace([
            'type' => 'lodging', 'name' => 'Hotel Batam', 'lat' => 1.1300, 'lng' => 104.0300,
            'external_place_id' => 'gp-hotel',
        ]);
        $trip->interestCategories()->attach($category->categories_id);
        $trip->update([
            'weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25,
        ]);
        $this->setTripStart($trip, ['start_places_id' => $hotel->places_id]);

        return $trip->fresh();
    }

    public function test_generate_builds_an_itinerary_from_wishlist_and_fills_empty_slots_with_recommendations(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);
        $category = $trip->interestCategories()->first();

        $wishlistA = $this->makePlace(['name' => 'Wishlist A', 'lat' => 1.1301, 'lng' => 104.0301, 'external_place_id' => 'gp-wa']);
        $wishlistB = $this->makePlace(['name' => 'Wishlist B', 'lat' => 1.4800, 'lng' => 104.4800, 'external_place_id' => 'gp-wb']);
        $trip->wishlistPlaces()->create(['places_id' => $wishlistA->places_id]);
        $trip->wishlistPlaces()->create(['places_id' => $wishlistB->places_id]);

        $recommended = $this->makePlace(['name' => 'Rekomendasi', 'lat' => 1.1305, 'lng' => 104.0305, 'external_place_id' => 'gp-rec']);
        $recommended->categories()->attach($category->categories_id);

        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $days = $response->json('days');
        $this->assertCount(2, $days);

        $allPlaceIds = collect($days)->flatMap(fn ($day) => collect($day['items'])->pluck('places_id'));
        $this->assertContains($wishlistA->places_id, $allPlaceIds);
        $this->assertContains($wishlistB->places_id, $allPlaceIds);

        // No place appears on more than one day (US4 acceptance criteria).
        $this->assertSame($allPlaceIds->count(), $allPlaceIds->unique()->count());

        $this->assertDatabaseHas('itinerary_days', ['trips_id' => $trip->trips_id]);
        $this->assertDatabaseCount('itinerary_items', $allPlaceIds->count());
    }

    public function test_a_custom_pin_wishlist_item_becomes_a_stop_with_its_pin_snapshot(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        $trip->wishlistPlaces()->create([
            'custom_name' => 'Rumah Saudara', 'custom_lat' => 1.1302, 'custom_lng' => 104.0302,
            'custom_visit_minutes' => 45,
        ]);

        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $this->assertDatabaseHas('itinerary_items', [
            'places_id' => null,
            'source' => 'wishlist',
            'custom_name' => 'Rumah Saudara',
            'custom_visit_minutes' => 45,
        ]);

        $detail = $this->withHeaders($this->authHeader($user))->getJson("/api/trips/{$trip->trips_id}");
        $stop = collect($detail->json('days.0.items'))->firstWhere('custom_name', 'Rumah Saudara');
        $this->assertNull($stop['place']);
        $this->assertEqualsWithDelta(1.1302, (float) $stop['custom_lat'], 0.0001);
    }

    public function test_wishlist_items_are_geographically_clustered_into_separate_days(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);

        // Two tight clusters far apart from each other.
        $clusterA1 = $this->makePlace(['name' => 'A1', 'lat' => 1.1300, 'lng' => 104.0300, 'external_place_id' => 'gp-a1']);
        $clusterA2 = $this->makePlace(['name' => 'A2', 'lat' => 1.1310, 'lng' => 104.0310, 'external_place_id' => 'gp-a2']);
        $clusterB1 = $this->makePlace(['name' => 'B1', 'lat' => 1.5000, 'lng' => 104.5000, 'external_place_id' => 'gp-b1']);
        $clusterB2 = $this->makePlace(['name' => 'B2', 'lat' => 1.5010, 'lng' => 104.5010, 'external_place_id' => 'gp-b2']);

        foreach ([$clusterA1, $clusterA2, $clusterB1, $clusterB2] as $place) {
            $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);
        }

        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $days = collect($response->json('days'));

        $dayOfA1 = $days->first(fn ($day) => collect($day['items'])->contains('places_id', $clusterA1->places_id));
        $dayOfA2 = $days->first(fn ($day) => collect($day['items'])->contains('places_id', $clusterA2->places_id));
        $dayOfB1 = $days->first(fn ($day) => collect($day['items'])->contains('places_id', $clusterB1->places_id));

        $this->assertSame($dayOfA1['day_number'], $dayOfA2['day_number']);
        $this->assertNotSame($dayOfA1['day_number'], $dayOfB1['day_number']);
    }

    public function test_a_manually_swapped_style_place_with_no_score_has_null_topsis_score_only_when_source_is_recommended(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1301, 'lng' => 104.0301, 'external_place_id' => 'gp-w']);
        $trip->wishlistPlaces()->create(['places_id' => $wishlist->places_id]);

        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $items = collect($response->json('days.0.items'));
        $wishlistItem = $items->firstWhere('places_id', $wishlist->places_id);

        $this->assertSame('wishlist', $wishlistItem['source']);
        $this->assertNull($wishlistItem['topsis_score']);
    }

    public function test_regenerating_replaces_the_previous_itinerary(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1301, 'lng' => 104.0301, 'external_place_id' => 'gp-w']);
        $trip->wishlistPlaces()->create(['places_id' => $wishlist->places_id]);
        $this->fakeRoutes();

        $headers = $this->authHeader($user);
        $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/generate")->assertOk();
        $firstCount = $trip->days()->count();

        $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/generate")->assertOk();
        $secondCount = $trip->fresh()->days()->count();

        $this->assertSame($firstCount, $secondCount);
        $this->assertSame(1, $secondCount);
    }

    public function test_a_day_with_no_reachable_stops_is_flagged_tidak_muat(): void
    {
        $user = User::factory()->create();
        // No places in the catalog at all besides the hotel - nothing to
        // recommend, day should come back empty and flagged.
        $trip = $this->readyTrip($user, 1);

        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $this->assertTrue($response->json('days.0.tidak_muat'));
        $this->assertCount(0, $response->json('days.0.items'));
    }

    public function test_generate_shows_up_in_the_trip_detail_afterward(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1301, 'lng' => 104.0301, 'external_place_id' => 'gp-w']);
        $trip->wishlistPlaces()->create(['places_id' => $wishlist->places_id]);
        $this->fakeRoutes();

        $headers = $this->authHeader($user);
        $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/generate")->assertOk();

        $response = $this->withHeaders($headers)->getJson("/api/trips/{$trip->trips_id}");

        $response->assertOk();
        $this->assertCount(1, $response->json('days'));
        $this->assertNotEmpty($response->json('days.0.items'));
        $this->assertNotNull($response->json('days.0.items.0.polyline_to_here'));
    }

    // --- opening hours (tingkat 1) ---

    /**
     * Stored hours closed on the given ISO weekdays and open 09:00-17:00 on the others.
     */
    private static function hoursClosedOn(array $isoWeekdays): array
    {
        $rows = [];
        foreach (array_keys(\App\Services\Places\OpeningHours::DAYS) as $index => $day) {
            $rows[$day] = in_array($index + 1, $isoWeekdays, true)
                ? ['state' => 'closed']
                : ['state' => 'open', 'open' => '09:00', 'close' => '17:00'];
        }

        return \App\Services\Places\OpeningHours::fromForm($rows);
    }

    private function nextSaturday(): string
    {
        return now()->next(\Carbon\Carbon::SATURDAY)->toDateString();
    }

    public function test_a_place_closed_on_the_trip_day_is_not_recommended(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        $trip->update(['start_date' => $this->nextSaturday()]);
        $category = $trip->interestCategories()->first();

        $closed = $this->makePlace(['name' => 'Tutup Sabtu', 'lat' => 1.1301, 'lng' => 104.0301, 'opening_hours' => self::hoursClosedOn([6])]);
        $open = $this->makePlace(['name' => 'Buka Sabtu', 'lat' => 1.1302, 'lng' => 104.0302, 'opening_hours' => self::hoursClosedOn([1])]);
        $unknown = $this->makePlace(['name' => 'Jam Tidak Diketahui', 'lat' => 1.1303, 'lng' => 104.0303]);
        foreach ([$closed, $open, $unknown] as $place) {
            $place->categories()->attach($category->categories_id);
        }
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $placeIds = collect($response->json('days.0.items'))->pluck('places_id');
        $this->assertNotContains($closed->places_id, $placeIds);
        $this->assertContains($open->places_id, $placeIds);
        // Unknown hours count as open.
        $this->assertContains($unknown->places_id, $placeIds);
    }

    public function test_a_wishlist_place_moves_off_its_closed_day(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);
        $trip->update(['start_date' => $this->nextSaturday()]);
        $museum = $this->makePlace(['name' => 'Museum Tutup Sabtu', 'lat' => 1.1301, 'lng' => 104.0301, 'opening_hours' => self::hoursClosedOn([6])]);
        $trip->wishlistPlaces()->create(['places_id' => $museum->places_id]);
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk()->assertJsonPath('closed_wishlist_places', []);
        $dayOfMuseum = collect($response->json('days'))
            ->first(fn ($day) => collect($day['items'])->contains('places_id', $museum->places_id));
        // Day 1 is Saturday, day 2 Sunday.
        $this->assertSame(2, $dayOfMuseum['day_number']);
    }

    public function test_a_wishlist_place_closed_on_every_trip_day_is_left_out_and_reported(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);
        $trip->update(['start_date' => $this->nextSaturday()]);
        $office = $this->makePlace(['name' => 'Tutup Akhir Pekan', 'lat' => 1.1301, 'lng' => 104.0301, 'opening_hours' => self::hoursClosedOn([6, 7])]);
        $trip->wishlistPlaces()->create(['places_id' => $office->places_id]);
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk()
            ->assertJsonPath('closed_wishlist_places', ['Tutup Akhir Pekan'])
            ->assertJsonPath('dropped_wishlist_places', []);
        $allPlaceIds = collect($response->json('days'))->flatMap(fn ($day) => collect($day['items'])->pluck('places_id'));
        $this->assertNotContains($office->places_id, $allPlaceIds);
    }

    // --- start and end per day ---

    public function test_a_new_trip_gets_one_day_row_per_day(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeader($user))->postJson('/api/trips', [
            'num_days' => 3, 'budget_total' => 1000000, 'start_date' => now()->addWeek()->toDateString(),
        ]);

        $response->assertCreated();
        $trip = Trip::find($response->json('trips_id'));
        $this->assertSame([1, 2, 3], $trip->days()->orderBy('day_number')->pluck('day_number')->all());
    }

    public function test_a_day_starting_at_another_hotel_gets_the_wishlist_near_that_hotel(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);
        $farHotel = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Jauh', 'lat' => 1.5000, 'lng' => 104.5000]);
        $trip->days()->where('day_number', 2)->update(['start_places_id' => $farHotel->places_id]);

        $near = $this->makePlace(['name' => 'Dekat Hotel 1', 'lat' => 1.1310, 'lng' => 104.0310]);
        $far = $this->makePlace(['name' => 'Dekat Hotel 2', 'lat' => 1.5010, 'lng' => 104.5010]);
        foreach ([$far, $near] as $place) {
            $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);
        }
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $dayOf = fn (Place $place) => collect($response->json('days'))
            ->first(fn ($day) => collect($day['items'])->contains('places_id', $place->places_id))['day_number'] ?? null;
        $this->assertSame(1, $dayOf($near));
        $this->assertSame(2, $dayOf($far));
    }

    public function test_a_day_ending_elsewhere_visits_the_stop_nearest_that_end_last(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        // The hotel is at 1.13, 104.03; the day ends a little east of it.
        $trip->days()->update(['end_custom_name' => 'Hotel Kedua', 'end_lat' => 1.1300, 'end_lng' => 104.0500]);

        $nearEnd = $this->makePlace(['name' => 'Dekat Akhir', 'lat' => 1.1300, 'lng' => 104.0500]);
        $north = $this->makePlace(['name' => 'Utara', 'lat' => 1.2000, 'lng' => 104.0300]);
        foreach ([$nearEnd, $north] as $place) {
            $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);
        }
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        // Nearest-first alone would go to "Dekat Akhir" first.
        $wishlistOrder = collect($response->json('days.0.items'))
            ->whereIn('places_id', [$nearEnd->places_id, $north->places_id])
            ->sortBy('visit_order')
            ->pluck('places_id')
            ->values()
            ->all();
        $this->assertSame([$north->places_id, $nearEnd->places_id], $wishlistOrder);
        $this->assertNotNull($trip->days()->first()->polyline_to_end);
    }

    public function test_changing_a_days_points_after_generating_recomputes_only_that_days_route(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1310, 'lng' => 104.0310]);
        $trip->wishlistPlaces()->create(['places_id' => $wishlist->places_id]);
        $this->fakeRoutes();
        $headers = $this->authHeader($user);
        $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/generate")->assertOk();
        $placesBefore = $trip->days()->with('items')->get()->mapWithKeys(fn ($day) => [$day->day_number => $day->items->pluck('places_id')->sort()->values()->all()]);
        $callsBefore = count(Http::recorded());

        $response = $this->withHeaders($headers)->putJson("/api/trips/{$trip->trips_id}/days/1/points", [
            'end' => ['custom_name' => 'Rumah Teman', 'custom_lat' => 1.1400, 'custom_lng' => 104.0400],
        ]);

        $response->assertOk()
            ->assertJsonPath('days.0.end.name', 'Rumah Teman')
            ->assertJsonPath('days.0.has_own_end', true)
            ->assertJsonPath('days.1.has_own_end', false);
        $this->assertSame(1, count(Http::recorded()) - $callsBefore);
        $placesAfter = $trip->days()->with('items')->get()->mapWithKeys(fn ($day) => [$day->day_number => $day->items->pluck('places_id')->sort()->values()->all()]);
        $this->assertSame($placesBefore->all(), $placesAfter->all());

        $reset = $this->withHeaders($headers)->putJson("/api/trips/{$trip->trips_id}/days/1/points", ['end' => null]);
        $reset->assertOk()->assertJsonPath('days.0.has_own_end', false)->assertJsonPath('days.0.end.name', 'Hotel Batam');
    }

    public function test_day_points_are_validated(): void
    {
        $owner = User::factory()->create();
        $trip = $this->readyTrip($owner, 2);
        $hotel = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Lain']);

        $this->withHeaders($this->authHeader($owner))
            ->putJson("/api/trips/{$trip->trips_id}/days/3/points", ['start' => ['places_id' => $hotel->places_id]])
            ->assertNotFound();
        $this->withHeaders($this->authHeader($owner))
            ->putJson("/api/trips/{$trip->trips_id}/days/1/points", [
                'start' => ['places_id' => $hotel->places_id, 'custom_name' => 'X', 'custom_lat' => 1.1, 'custom_lng' => 104.0],
            ])
            ->assertUnprocessable();

        $this->withHeaders($this->authHeader($owner))
            ->putJson("/api/trips/{$trip->trips_id}/days/2/points", ['start' => ['places_id' => $hotel->places_id]])
            ->assertOk()
            ->assertJsonPath('days.1.start.name', 'Hotel Lain')
            ->assertJsonPath('days.0.start.name', 'Hotel Batam');
    }

    public function test_only_the_owner_can_change_day_points(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->readyTrip($owner, 2);
        $hotel = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Lain']);

        $this->withHeaders($this->authHeader($stranger))
            ->putJson("/api/trips/{$trip->trips_id}/days/1/points", ['start' => ['places_id' => $hotel->places_id]])
            ->assertForbidden();
    }

    public function test_changing_the_number_of_days_keeps_the_remaining_days_points(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 3);
        $hotel = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Hari Dua']);
        $trip->days()->where('day_number', 2)->update(['start_places_id' => $hotel->places_id]);

        $this->withHeaders($this->authHeader($user))->patchJson("/api/trips/{$trip->trips_id}", ['num_days' => 2])->assertOk();
        $this->assertSame([1, 2], $trip->days()->orderBy('day_number')->pluck('day_number')->all());
        $this->assertSame($hotel->places_id, $trip->days()->where('day_number', 2)->value('start_places_id'));

        $this->withHeaders($this->authHeader($user))->patchJson("/api/trips/{$trip->trips_id}", ['num_days' => 4])->assertOk();
        // New days start where the last day did.
        $this->assertSame($hotel->places_id, $trip->days()->where('day_number', 4)->value('start_places_id'));
    }
}
