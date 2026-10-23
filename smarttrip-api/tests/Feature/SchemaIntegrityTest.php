<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlacePhoto;
use App\Models\PlaceReview;
use App\Models\Trip;
use App\Models\TripViewer;
use App\Models\TripWishlistPlace;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Exercises the full docs/prd Section 10 data model end-to-end: every
 * table, its relationships, and that a full itinerary can be assembled
 * through the models exactly as the design spec describes the flow.
 */
class SchemaIntegrityTest extends TestCase
{
    use RefreshDatabase;

    public function test_a_full_trip_can_be_assembled_through_every_table_and_relationship(): void
    {
        $user = User::factory()->create();

        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $user->defaultInterestCategories()->attach($culinary->categories_id);

        $hotel = Place::create([
            'name' => 'Hotel Batam View', 'type' => 'lodging', 'lat' => 1.1301, 'lng' => 104.0529,
            'address' => 'Jl. Contoh No.1', 'source' => 'manual',
        ]);
        $cafe = Place::create([
            'name' => 'Kafe Tepi Laut', 'type' => 'culinary', 'lat' => 1.1401, 'lng' => 104.0601,
            'address' => 'Jl. Pantai No.2', 'source' => 'google', 'external_place_id' => 'gp-1',
            'is_outdoor' => true, 'estimated_cost_idr' => 75000,
        ]);
        $beachSpot = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.1501, 'lng' => 104.0701,
            'address' => 'Nongsa', 'source' => 'google', 'external_place_id' => 'gp-2', 'is_outdoor' => true,
        ]);

        $cafe->categories()->attach($culinary->categories_id);
        $beachSpot->categories()->attach($beach->categories_id);

        PlacePhoto::create(['places_id' => $cafe->places_id, 'photo_url' => 'cafe-1.jpg', 'sort_order' => 0]);

        PlaceCandidate::create([
            'external_place_id' => 'gp-candidate-1', 'name' => 'Warung Baru', 'type' => 'restaurant',
            'lat' => 1.1, 'lng' => 104.0, 'search_area' => 'Nongsa',
        ]);

        $trip = Trip::create([
            'users_id' => $user->users_id, 'title' => 'Liburan Batam 3 Hari', 'num_days' => 3,
            'budget_total' => 1_500_000, 'has_own_hotel' => false,
            'start_date' => now()->addWeek()->toDateString(),
            'weight_kategori' => 0.4, 'weight_jarak' => 0.2, 'weight_anggaran' => 0.2, 'weight_rating' => 0.2,
        ]);
        $trip->interestCategories()->attach([$culinary->categories_id, $beach->categories_id]);

        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $cafe->places_id]);
        TripWishlistPlace::create([
            'trips_id' => $trip->trips_id, 'custom_name' => 'Spot foto pribadi',
            'custom_lat' => 1.16, 'custom_lng' => 104.08, 'custom_visit_minutes' => 30,
        ]);

        $day1 = ItineraryDay::create([
            'trips_id' => $trip->trips_id, 'day_number' => 1, 'start_places_id' => $hotel->places_id,
        ]);

        $item1 = ItineraryItem::create([
            'itinerary_days_id' => $day1->itinerary_days_id, 'places_id' => $cafe->places_id,
            'visit_order' => 1, 'topsis_score' => 0.8421, 'source' => 'wishlist',
        ]);
        ItineraryItem::create([
            'itinerary_days_id' => $day1->itinerary_days_id, 'places_id' => $beachSpot->places_id,
            'visit_order' => 2, 'topsis_score' => null, 'source' => 'recommended',
        ]);

        PlaceReview::create([
            'places_id' => $cafe->places_id, 'users_id' => $user->users_id, 'rating' => 5,
            'comment' => 'Enak banget!', 'itinerary_items_id' => $item1->itinerary_items_id,
        ]);

        $viewer = User::factory()->create();
        TripViewer::create(['trips_id' => $trip->trips_id, 'users_id' => $viewer->users_id, 'added_at' => now()]);

        // Round-trip through the relationships, the way the API layer will.
        $this->assertCount(2, $trip->fresh()->interestCategories);
        $this->assertCount(2, $day1->fresh()->items);
        $this->assertSame($hotel->places_id, $day1->fresh()->startPlace->places_id);
        $this->assertTrue($viewer->sharedTrips->contains('trips_id', $trip->trips_id));
        $this->assertCount(1, $cafe->fresh()->reviews);
        $this->assertCount(1, $cafe->fresh()->photos);
        $this->assertTrue($user->fresh()->defaultInterestCategories->contains('categories_id', $culinary->categories_id));
    }

    public function test_a_place_category_cannot_reference_a_missing_category(): void
    {
        $place = Place::create([
            'name' => 'Tempat', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.0,
            'address' => 'Alamat', 'source' => 'manual',
        ]);

        $this->expectException(QueryException::class);

        $place->categories()->attach(99999);
    }

    public function test_a_user_cannot_review_the_same_place_twice(): void
    {
        $user = User::factory()->create();
        $place = Place::create([
            'name' => 'Tempat', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.0,
            'address' => 'Alamat', 'source' => 'manual',
        ]);

        PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 4]);

        $this->expectException(QueryException::class);

        PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 2]);
    }

    // --- unique constraints added 2026-10-10 (previously code-only invariants) ---

    private function scaffoldTripWithPlace(): array
    {
        $user = User::factory()->create();
        $trip = Trip::create(['users_id' => $user->users_id, 'title' => 'Trip', 'num_days' => 1, 'budget_total' => 100000, 'start_date' => now()->toDateString()]);
        $place = Place::create(['name' => 'Tempat', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.0, 'address' => 'Batam', 'source' => 'manual']);

        return [$trip, $place];
    }

    public function test_a_place_cannot_be_wishlisted_twice_on_the_same_trip(): void
    {
        [$trip, $place] = $this->scaffoldTripWithPlace();
        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $place->places_id]);

        $this->expectException(QueryException::class);
        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $place->places_id]);
    }

    public function test_a_trip_cannot_have_two_days_with_the_same_day_number(): void
    {
        [$trip] = $this->scaffoldTripWithPlace();
        ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);

        $this->expectException(QueryException::class);
        ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
    }

    public function test_a_place_cannot_appear_twice_on_the_same_day(): void
    {
        [$trip, $place] = $this->scaffoldTripWithPlace();
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        ItineraryItem::create(['itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id, 'visit_order' => 1, 'source' => 'recommended']);

        $this->expectException(QueryException::class);
        ItineraryItem::create(['itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id, 'visit_order' => 2, 'source' => 'recommended']);
    }

    public function test_a_place_cannot_have_two_photos_with_the_same_sort_order(): void
    {
        [, $place] = $this->scaffoldTripWithPlace();
        PlacePhoto::create(['places_id' => $place->places_id, 'photo_url' => 'a.jpg', 'sort_order' => 0]);

        $this->expectException(QueryException::class);
        PlacePhoto::create(['places_id' => $place->places_id, 'photo_url' => 'b.jpg', 'sort_order' => 0]);
    }

    public function test_trip_history_relations_still_resolve_a_soft_deleted_place(): void
    {
        [$trip, $place] = $this->scaffoldTripWithPlace();
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1, 'start_places_id' => $place->places_id]);
        $item = ItineraryItem::create(['itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id, 'visit_order' => 1, 'source' => 'wishlist']);
        $wishlist = TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $place->places_id]);

        $place->delete();

        $this->assertSame('Tempat', $item->fresh()->place->name);
        $this->assertSame('Tempat', $wishlist->fresh()->place->name);
        $this->assertSame('Tempat', $day->fresh()->startPlace->name);
        $this->assertNull(Place::find($place->places_id));
    }
}
