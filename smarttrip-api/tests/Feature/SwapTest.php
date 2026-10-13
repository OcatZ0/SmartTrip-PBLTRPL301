<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\Trip;
use App\Models\User;
use App\Services\Itinerary\EncodedPolyline;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class SwapTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Tempat', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
            'estimated_visit_minutes' => 60, 'rating' => 4.0,
        ], $overrides));
    }

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

    /**
     * Trip lengkap dengan 1 item itinerary siap di-swap (hotel + bobot +
     * 1 stop wishlist attraction).
     */
    private function tripWithOneItem(User $owner): array
    {
        $trip = Trip::create([
            'users_id' => $owner->users_id, 'title' => 'Trip', 'num_days' => 1,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
            'weight_kategori' => 0.25, 'weight_jarak' => 0.25, 'weight_anggaran' => 0.25, 'weight_rating' => 0.25,
        ]);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $trip->interestCategories()->attach($category->categories_id);

        $hotel = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel', 'lat' => 1.1300, 'lng' => 104.0300, 'external_place_id' => 'gp-hotel']);
        $trip->update(['hotel_places_id' => $hotel->places_id]);

        $original = $this->makePlace(['name' => 'Tempat Asli', 'lat' => 1.1310, 'lng' => 104.0310, 'external_place_id' => 'gp-original']);
        $original->categories()->attach($category->categories_id);

        $day = ItineraryDay::create([
            'trips_id' => $trip->trips_id, 'day_number' => 1,
            'start_places_id' => $hotel->places_id, 'end_places_id' => $hotel->places_id,
        ]);
        $item = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $original->places_id,
            'visit_order' => 1, 'topsis_score' => 0.8, 'source' => 'wishlist',
            'polyline_to_here' => 'oldPolyline',
        ]);

        return compact('trip', 'day', 'item', 'category', 'hotel', 'original');
    }

    // --- swap-candidates ---

    public function test_swap_candidates_returns_ranked_alternatives_of_the_same_type(): void
    {
        $user = User::factory()->create();
        ['item' => $item, 'category' => $category] = $this->tripWithOneItem($user);

        $alt1 = $this->makePlace(['name' => 'Alternatif Bagus', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt1', 'rating' => 4.8]);
        $alt1->categories()->attach($category->categories_id);
        $lodgingNoise = $this->makePlace(['type' => 'lodging', 'name' => 'Hotel Lain', 'external_place_id' => 'gp-lodging-noise']);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/itinerary-items/{$item->itinerary_items_id}/swap-candidates");

        $response->assertOk();
        $names = collect($response->json('data'))->pluck('name');
        $this->assertContains('Alternatif Bagus', $names);
        $this->assertNotContains('Hotel Lain', $names);
    }

    public function test_swap_candidates_excludes_places_already_used_elsewhere_in_the_trip(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'day' => $day, 'hotel' => $hotel] = $this->tripWithOneItem($user);

        $usedElsewhere = $this->makePlace(['name' => 'Sudah Dipakai', 'lat' => 1.1312, 'lng' => 104.0312, 'external_place_id' => 'gp-used']);
        ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $usedElsewhere->places_id,
            'visit_order' => 2, 'topsis_score' => 0.5, 'source' => 'recommended',
        ]);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/itinerary-items/{$item->itinerary_items_id}/swap-candidates");

        $response->assertOk();
        $names = collect($response->json('data'))->pluck('name');
        $this->assertNotContains('Sudah Dipakai', $names);
    }

    public function test_swap_candidates_is_empty_but_not_an_error_when_no_alternatives_exist(): void
    {
        $user = User::factory()->create();
        ['item' => $item] = $this->tripWithOneItem($user);

        $response = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/itinerary-items/{$item->itinerary_items_id}/swap-candidates");

        $response->assertOk();
        $this->assertSame([], $response->json('data'));
    }

    public function test_a_viewer_can_see_swap_candidates(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        ['trip' => $trip, 'item' => $item] = $this->tripWithOneItem($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))
            ->getJson("/api/itinerary-items/{$item->itinerary_items_id}/swap-candidates");

        $response->assertOk();
    }

    public function test_a_stranger_cannot_see_swap_candidates(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        ['item' => $item] = $this->tripWithOneItem($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->getJson("/api/itinerary-items/{$item->itinerary_items_id}/swap-candidates");

        $response->assertForbidden();
    }

    // --- commit swap ---

    public function test_swapping_in_a_ranked_alternative_persists_its_known_topsis_score(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'category' => $category] = $this->tripWithOneItem($user);
        $alt = $this->makePlace(['name' => 'Alternatif', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt']);
        $alt->categories()->attach($category->categories_id);
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id]);

        $response->assertOk();
        $item->refresh();
        $this->assertSame($alt->places_id, $item->places_id);
        $this->assertNotNull($item->topsis_score);
    }

    public function test_swapping_in_a_manually_searched_place_leaves_topsis_score_null(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item] = $this->tripWithOneItem($user);
        // A lodging is never part of the (attraction) swap-candidate pool -
        // stands in for "picked via full manual catalog search".
        $manualPick = $this->makePlace(['type' => 'lodging', 'name' => 'Hasil Cari Manual', 'lat' => 1.4000, 'lng' => 104.4000, 'external_place_id' => 'gp-manual']);
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $manualPick->places_id]);

        $response->assertOk();
        $item->refresh();
        $this->assertSame($manualPick->places_id, $item->places_id);
        $this->assertNull($item->topsis_score);
    }

    public function test_swap_resets_visited_at_on_the_swapped_item(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'category' => $category] = $this->tripWithOneItem($user);
        $item->update(['visited_at' => now()]);
        $alt = $this->makePlace(['name' => 'Alternatif', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt']);
        $alt->categories()->attach($category->categories_id);
        $this->fakeRoutes();

        $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id])
            ->assertOk();

        $this->assertNull($item->fresh()->visited_at);
    }

    public function test_swap_does_not_reset_visited_at_on_other_items_in_the_same_day(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'day' => $day, 'category' => $category] = $this->tripWithOneItem($user);

        $otherPlace = $this->makePlace(['name' => 'Stop Lain', 'lat' => 1.1315, 'lng' => 104.0315, 'external_place_id' => 'gp-other']);
        $otherItem = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $otherPlace->places_id,
            'visit_order' => 2, 'topsis_score' => 0.6, 'source' => 'recommended', 'visited_at' => now(),
        ]);

        $alt = $this->makePlace(['name' => 'Alternatif', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt']);
        $alt->categories()->attach($category->categories_id);
        $this->fakeRoutes();

        $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id])
            ->assertOk();

        $this->assertNotNull($otherItem->fresh()->visited_at);
    }

    public function test_swap_refreshes_the_polyline_and_reorders_the_day(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'category' => $category] = $this->tripWithOneItem($user);
        $alt = $this->makePlace(['name' => 'Alternatif', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt']);
        $alt->categories()->attach($category->categories_id);
        $this->fakeRoutes();

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id]);

        $response->assertOk();
        $item->refresh();
        // First leg of the faked route: hotel waypoint -> the only stop.
        $this->assertSame(
            EncodedPolyline::encode([['lat' => 1.1, 'lng' => 104.0], ['lat' => 1.11, 'lng' => 104.01]]),
            $item->polyline_to_here
        );
        $this->assertSame(1, $item->visit_order);
    }

    public function test_swap_does_not_affect_other_days_in_the_trip(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'category' => $category, 'hotel' => $hotel] = $this->tripWithOneItem($user);

        $otherDayPlace = $this->makePlace(['name' => 'Hari Lain', 'lat' => 1.5000, 'lng' => 104.5000, 'external_place_id' => 'gp-otherday']);
        $otherDay = ItineraryDay::create([
            'trips_id' => $trip->trips_id, 'day_number' => 2,
            'start_places_id' => $hotel->places_id, 'end_places_id' => $hotel->places_id,
        ]);
        $otherDayItem = ItineraryItem::create([
            'itinerary_days_id' => $otherDay->itinerary_days_id, 'places_id' => $otherDayPlace->places_id,
            'visit_order' => 1, 'topsis_score' => 0.7, 'source' => 'wishlist', 'polyline_to_here' => 'untouchedPolyline',
        ]);

        $alt = $this->makePlace(['name' => 'Alternatif', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt']);
        $alt->categories()->attach($category->categories_id);
        $this->fakeRoutes();

        $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id])
            ->assertOk();

        $otherDayItem->refresh();
        $this->assertSame($otherDayPlace->places_id, $otherDayItem->places_id);
        $this->assertSame('untouchedPolyline', $otherDayItem->polyline_to_here);
    }

    public function test_a_custom_pin_stop_can_be_swapped_for_a_catalog_place(): void
    {
        $user = User::factory()->create();
        ['day' => $day, 'category' => $category] = $this->tripWithOneItem($user);
        $pin = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => null,
            'visit_order' => 2, 'source' => 'wishlist',
            'custom_name' => 'Rumah Saudara', 'custom_lat' => 1.1320, 'custom_lng' => 104.0320,
            'custom_visit_minutes' => 30,
        ]);
        $alternative = $this->makePlace(['name' => 'Kuliner', 'type' => 'culinary', 'lat' => 1.1330, 'lng' => 104.0330, 'external_place_id' => 'gp-alt']);
        $alternative->categories()->attach($category->categories_id);
        $this->fakeRoutes();

        $candidates = $this->withHeaders($this->authHeader($user))
            ->getJson("/api/itinerary-items/{$pin->itinerary_items_id}/swap-candidates");
        $candidates->assertOk();
        $this->assertContains($alternative->places_id, array_column($candidates->json('data'), 'places_id'));

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$pin->itinerary_items_id}", ['places_id' => $alternative->places_id]);

        $response->assertOk();
        $pin->refresh();
        $this->assertSame($alternative->places_id, $pin->places_id);
        $this->assertNull($pin->custom_name);
        $this->assertNull($pin->custom_visit_minutes);
    }

    public function test_cannot_swap_in_a_place_already_used_elsewhere_in_the_trip(): void
    {
        $user = User::factory()->create();
        ['trip' => $trip, 'item' => $item, 'day' => $day] = $this->tripWithOneItem($user);

        $usedElsewhere = $this->makePlace(['name' => 'Sudah Dipakai', 'lat' => 1.1312, 'lng' => 104.0312, 'external_place_id' => 'gp-used']);
        ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $usedElsewhere->places_id,
            'visit_order' => 2, 'topsis_score' => 0.5, 'source' => 'recommended',
        ]);

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $usedElsewhere->places_id]);

        $response->assertUnprocessable();
    }

    public function test_a_non_owner_cannot_commit_a_swap(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        ['item' => $item, 'category' => $category] = $this->tripWithOneItem($owner);
        $alt = $this->makePlace(['name' => 'Alternatif', 'external_place_id' => 'gp-alt']);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id]);

        $response->assertForbidden();
    }

    public function test_a_viewer_cannot_commit_a_swap(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        ['trip' => $trip, 'item' => $item] = $this->tripWithOneItem($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);
        $alt = $this->makePlace(['name' => 'Alternatif', 'external_place_id' => 'gp-alt']);

        $response = $this->withHeaders($this->authHeader($viewer))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id]);

        $response->assertForbidden();
    }

    public function test_a_google_routes_failure_during_swap_returns_a_clean_error_not_a_500(): void
    {
        $user = User::factory()->create();
        ['item' => $item, 'category' => $category] = $this->tripWithOneItem($user);
        $alt = $this->makePlace(['name' => 'Alternatif', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-alt']);
        $alt->categories()->attach($category->categories_id);
        Http::fake(['api.openrouteservice.org/*' => Http::response(['error' => 'boom'], 403)]);

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/itinerary-items/{$item->itinerary_items_id}", ['places_id' => $alt->places_id]);

        $response->assertUnprocessable();
        // The swap itself must not be partially committed if the routes
        // refresh fails - the whole thing rolls back together.
        $this->assertSame('Tempat Asli', $item->fresh()->place->name);
    }

    // --- manual search via near_itinerary_day ---

    public function test_places_can_be_searched_near_an_itinerary_day(): void
    {
        $user = User::factory()->create();
        ['day' => $day] = $this->tripWithOneItem($user);

        $near = $this->makePlace(['name' => 'Dekat', 'lat' => 1.1311, 'lng' => 104.0311, 'external_place_id' => 'gp-near']);
        $far = $this->makePlace(['name' => 'Jauh', 'lat' => 1.9000, 'lng' => 104.9000, 'external_place_id' => 'gp-far']);

        $response = $this->getJson("/api/places?near_itinerary_day={$day->itinerary_days_id}");

        $response->assertOk();
        $names = collect($response->json('data'))->pluck('name')->all();
        $this->assertContains('Dekat', $names);
        $this->assertContains('Jauh', $names);
        $this->assertLessThan(array_search('Jauh', $names), array_search('Dekat', $names));
    }

    public function test_searching_near_a_missing_day_404s(): void
    {
        $response = $this->getJson('/api/places?near_itinerary_day=99999');

        $response->assertNotFound();
    }
}
