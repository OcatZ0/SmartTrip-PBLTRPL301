<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
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
            'address' => 'Batam', 'source' => 'google', 'google_place_id' => uniqid('gp-'),
            'estimated_visit_minutes' => 60, 'rating' => 4.0,
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
        for ($i = 0; $i < $waypointCount; $i++) {
            $coordinates[] = [104.0 + $i / 100, 1.1 + $i / 100];
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
        $this->assertSame($hotel->places_id, $trip->fresh()->hotel_places_id);
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
        $trip->refresh();
        $this->assertNull($trip->hotel_places_id);
        $this->assertSame('Rumah Saudara', $trip->hotel_custom_name);
    }

    public function test_hotel_options_ranks_lodgings_by_topsis(): void
    {
        $user = User::factory()->create();
        $trip = $this->makeTrip($user);
        $trip->update(['weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25]);

        // Near + cheap + highly rated should clearly outrank far + expensive + poorly rated.
        $this->makePlace([
            'type' => 'lodging', 'name' => 'Hotel Dekat', 'lat' => 1.150, 'lng' => 104.050,
            'estimated_cost_idr' => 100000, 'rating' => 4.8,
        ]);
        $this->makePlace([
            'type' => 'lodging', 'name' => 'Hotel Jauh', 'lat' => 1.500, 'lng' => 104.500,
            'estimated_cost_idr' => 900000, 'rating' => 2.5, 'google_place_id' => 'gp-far',
        ]);
        $this->makePlace([
            'type' => 'attraction', 'name' => 'Wishlist Anchor', 'lat' => 1.151, 'lng' => 104.051,
            'google_place_id' => 'gp-anchor',
        ]);
        $anchor = Place::where('name', 'Wishlist Anchor')->first();
        $trip->wishlistPlaces()->create(['places_id' => $anchor->places_id]);

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
        $trip->update(['hotel_places_id' => $hotel->places_id]);

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
            'google_place_id' => 'gp-hotel',
        ]);
        $trip->interestCategories()->attach($category->categories_id);
        $trip->update([
            'hotel_places_id' => $hotel->places_id,
            'weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25,
        ]);

        return $trip->fresh();
    }

    public function test_generate_builds_an_itinerary_from_wishlist_and_fills_empty_slots_with_recommendations(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 2);
        $category = $trip->interestCategories()->first();

        $wishlistA = $this->makePlace(['name' => 'Wishlist A', 'lat' => 1.1301, 'lng' => 104.0301, 'google_place_id' => 'gp-wa']);
        $wishlistB = $this->makePlace(['name' => 'Wishlist B', 'lat' => 1.4800, 'lng' => 104.4800, 'google_place_id' => 'gp-wb']);
        $trip->wishlistPlaces()->create(['places_id' => $wishlistA->places_id]);
        $trip->wishlistPlaces()->create(['places_id' => $wishlistB->places_id]);

        $recommended = $this->makePlace(['name' => 'Rekomendasi', 'lat' => 1.1305, 'lng' => 104.0305, 'google_place_id' => 'gp-rec']);
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
        $clusterA1 = $this->makePlace(['name' => 'A1', 'lat' => 1.1300, 'lng' => 104.0300, 'google_place_id' => 'gp-a1']);
        $clusterA2 = $this->makePlace(['name' => 'A2', 'lat' => 1.1310, 'lng' => 104.0310, 'google_place_id' => 'gp-a2']);
        $clusterB1 = $this->makePlace(['name' => 'B1', 'lat' => 1.5000, 'lng' => 104.5000, 'google_place_id' => 'gp-b1']);
        $clusterB2 = $this->makePlace(['name' => 'B2', 'lat' => 1.5010, 'lng' => 104.5010, 'google_place_id' => 'gp-b2']);

        foreach ([$clusterA1, $clusterA2, $clusterB1, $clusterB2] as $place) {
            $trip->wishlistPlaces()->create(['places_id' => $place->places_id]);
        }

        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/trips/{$trip->trips_id}/generate");

        $response->assertOk();
        $days = collect($response->json('days'));

        $dayOfA1 = $days->first(fn ($d) => collect($d['items'])->contains('places_id', $clusterA1->places_id));
        $dayOfA2 = $days->first(fn ($d) => collect($d['items'])->contains('places_id', $clusterA2->places_id));
        $dayOfB1 = $days->first(fn ($d) => collect($d['items'])->contains('places_id', $clusterB1->places_id));

        $this->assertSame($dayOfA1['day_number'], $dayOfA2['day_number']);
        $this->assertNotSame($dayOfA1['day_number'], $dayOfB1['day_number']);
    }

    public function test_a_manually_swapped_style_place_with_no_score_has_null_topsis_score_only_when_source_is_recommended(): void
    {
        $user = User::factory()->create();
        $trip = $this->readyTrip($user, 1);
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1301, 'lng' => 104.0301, 'google_place_id' => 'gp-w']);
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
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1301, 'lng' => 104.0301, 'google_place_id' => 'gp-w']);
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
        $wishlist = $this->makePlace(['name' => 'Wishlist', 'lat' => 1.1301, 'lng' => 104.0301, 'google_place_id' => 'gp-w']);
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
}
