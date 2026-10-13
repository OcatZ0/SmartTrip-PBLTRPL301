<?php

namespace Tests\Feature;

use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\PlaceReview;
use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ReviewTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
        ], $overrides));
    }

    // --- POST /api/places/{id}/reviews ---

    public function test_an_authenticated_user_can_review_a_place_with_no_visit_proof_required(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 5, 'comment' => 'Bagus sekali']);

        $response->assertCreated();
        $this->assertDatabaseHas('place_reviews', [
            'places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 5, 'comment' => 'Bagus sekali',
        ]);
    }

    public function test_a_review_can_be_submitted_without_a_comment(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 3]);

        $response->assertCreated();
        $this->assertDatabaseHas('place_reviews', ['places_id' => $place->places_id, 'rating' => 3, 'comment' => null]);
    }

    public function test_rating_must_be_between_one_and_five(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 6]);

        $response->assertUnprocessable();
    }

    public function test_reviewing_requires_authentication(): void
    {
        $place = $this->makePlace();

        $response = $this->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 4]);

        $response->assertUnauthorized();
    }

    public function test_reviewing_the_same_place_twice_is_rejected_and_points_to_the_existing_review(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $existing = PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 4]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 2]);

        $response->assertUnprocessable();
        $this->assertSame([$existing->place_reviews_id], $response->json('errors.place_reviews_id'));
        $this->assertSame(4, $existing->fresh()->rating);
    }

    public function test_a_review_can_be_linked_to_a_visited_itinerary_item_of_the_same_place(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $trip = Trip::create([
            'users_id' => $user->users_id, 'title' => 'Trip', 'num_days' => 1,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        $item = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'source' => 'wishlist', 'visited_at' => now(),
        ]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 5, 'itinerary_items_id' => $item->itinerary_items_id]);

        $response->assertCreated();
        $this->assertDatabaseHas('place_reviews', ['itinerary_items_id' => $item->itinerary_items_id]);
    }

    public function test_a_review_cannot_be_linked_to_an_itinerary_item_belonging_to_another_trip(): void
    {
        $user = User::factory()->create();
        $stranger = User::factory()->create();
        $place = $this->makePlace();
        $trip = Trip::create([
            'users_id' => $stranger->users_id, 'title' => 'Trip', 'num_days' => 1,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        $item = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $place->places_id,
            'visit_order' => 1, 'source' => 'wishlist',
        ]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 5, 'itinerary_items_id' => $item->itinerary_items_id]);

        $response->assertUnprocessable();
        $this->assertDatabaseMissing('place_reviews', ['places_id' => $place->places_id]);
    }

    public function test_a_review_cannot_be_linked_to_an_itinerary_item_of_a_different_place(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $otherPlace = $this->makePlace(['name' => 'Tempat Lain', 'external_place_id' => 'gp-other']);
        $trip = Trip::create([
            'users_id' => $user->users_id, 'title' => 'Trip', 'num_days' => 1,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ]);
        $day = ItineraryDay::create(['trips_id' => $trip->trips_id, 'day_number' => 1]);
        $item = ItineraryItem::create([
            'itinerary_days_id' => $day->itinerary_days_id, 'places_id' => $otherPlace->places_id,
            'visit_order' => 1, 'source' => 'wishlist',
        ]);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 5, 'itinerary_items_id' => $item->itinerary_items_id]);

        $response->assertUnprocessable();
    }

    // --- PATCH /api/reviews/{id} ---

    public function test_the_author_can_edit_their_own_review(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $review = PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 3, 'comment' => 'Biasa saja']);

        $response = $this->withHeaders($this->authHeader($user))
            ->patchJson("/api/reviews/{$review->place_reviews_id}", ['rating' => 5, 'comment' => 'Ternyata bagus']);

        $response->assertOk();
        $review->refresh();
        $this->assertSame(5, $review->rating);
        $this->assertSame('Ternyata bagus', $review->comment);
    }

    public function test_a_non_author_cannot_edit_someone_elses_review(): void
    {
        $author = User::factory()->create();
        $stranger = User::factory()->create();
        $place = $this->makePlace();
        $review = PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $author->users_id, 'rating' => 3]);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->patchJson("/api/reviews/{$review->place_reviews_id}", ['rating' => 1]);

        $response->assertForbidden();
        $this->assertSame(3, $review->fresh()->rating);
    }

    // --- DELETE /api/reviews/{id} ---

    public function test_the_author_can_delete_their_own_review(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $review = PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 3]);

        $response = $this->withHeaders($this->authHeader($user))
            ->deleteJson("/api/reviews/{$review->place_reviews_id}");

        $response->assertOk();
        $this->assertSoftDeleted($review);
    }

    public function test_deleting_a_review_frees_up_the_place_for_a_new_review_by_the_same_user(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $review = PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 3]);
        $headers = $this->authHeader($user);

        $this->withHeaders($headers)->deleteJson("/api/reviews/{$review->place_reviews_id}")->assertOk();

        $response = $this->withHeaders($headers)
            ->postJson("/api/places/{$place->places_id}/reviews", ['rating' => 4]);

        $response->assertCreated();
    }

    public function test_a_non_author_cannot_delete_someone_elses_review(): void
    {
        $author = User::factory()->create();
        $stranger = User::factory()->create();
        $place = $this->makePlace();
        $review = PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $author->users_id, 'rating' => 3]);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->deleteJson("/api/reviews/{$review->place_reviews_id}");

        $response->assertForbidden();
        $this->assertDatabaseHas('place_reviews', ['place_reviews_id' => $review->place_reviews_id, 'deleted_at' => null]);
    }

    // --- surfaced on place detail ---

    public function test_place_detail_includes_the_blended_rating_and_review_list(): void
    {
        $user = User::factory()->create(['name' => 'Budi']);
        $place = $this->makePlace(['rating' => 4.5]);
        PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $user->users_id, 'rating' => 5, 'comment' => 'Mantap']);

        $response = $this->getJson("/api/places/{$place->places_id}");

        $response->assertOk();
        $this->assertCount(1, $response->json('data.reviews'));
        $this->assertSame('Budi', $response->json('data.reviews.0.user_name'));
        $this->assertSame('Mantap', $response->json('data.reviews.0.comment'));
        $this->assertNotNull($response->json('data.rating'));
    }
}
