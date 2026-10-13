<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserWishlistTest extends TestCase
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
            'address' => 'Nongsa', 'source' => 'manual', 'estimated_visit_minutes' => 90,
        ], $overrides));
    }

    public function test_a_user_can_save_a_place_to_their_wishlist(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson('/api/wishlist', ['places_id' => $place->places_id]);

        $response->assertCreated();
        $this->assertDatabaseHas('user_wishlist_place', ['users_id' => $user->users_id, 'places_id' => $place->places_id]);
    }

    public function test_saving_the_same_place_twice_is_a_no_op(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $user->wishlistPlaces()->attach($place->places_id);

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson('/api/wishlist', ['places_id' => $place->places_id]);

        $response->assertOk();
        $this->assertDatabaseCount('user_wishlist_place', 1);
    }

    public function test_a_soft_deleted_place_cannot_be_saved(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $place->delete();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson('/api/wishlist', ['places_id' => $place->places_id]);

        $response->assertUnprocessable()->assertJsonValidationErrors('places_id');
    }

    public function test_the_wishlist_lists_only_the_users_own_places_newest_first(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $older = $this->makePlace(['name' => 'Lama']);
        $newer = $this->makePlace(['name' => 'Baru']);
        $notMine = $this->makePlace(['name' => 'Punya Orang']);
        $user->wishlistPlaces()->attach($older->places_id, ['added_at' => now()->subDay()]);
        $user->wishlistPlaces()->attach($newer->places_id, ['added_at' => now()]);
        $other->wishlistPlaces()->attach($notMine->places_id);

        $response = $this->withHeaders($this->authHeader($user))->getJson('/api/wishlist');

        $response->assertOk();
        $this->assertSame(['Baru', 'Lama'], array_column($response->json('data'), 'name'));
    }

    public function test_a_soft_deleted_place_drops_out_of_the_wishlist_and_can_still_be_removed(): void
    {
        $user = User::factory()->create();
        $place = $this->makePlace();
        $user->wishlistPlaces()->attach($place->places_id);
        $place->delete();

        $this->withHeaders($this->authHeader($user))->getJson('/api/wishlist')
            ->assertOk()
            ->assertJsonCount(0, 'data');

        $this->withHeaders($this->authHeader($user))->deleteJson("/api/wishlist/{$place->places_id}")
            ->assertOk();
        $this->assertDatabaseCount('user_wishlist_place', 0);
    }

    public function test_removing_only_touches_the_users_own_wishlist(): void
    {
        $user = User::factory()->create();
        $other = User::factory()->create();
        $place = $this->makePlace();
        $user->wishlistPlaces()->attach($place->places_id);
        $other->wishlistPlaces()->attach($place->places_id);

        $this->withHeaders($this->authHeader($user))->deleteJson("/api/wishlist/{$place->places_id}")
            ->assertOk();

        $this->assertDatabaseMissing('user_wishlist_place', ['users_id' => $user->users_id]);
        $this->assertDatabaseHas('user_wishlist_place', ['users_id' => $other->users_id, 'places_id' => $place->places_id]);
    }

    public function test_the_wishlist_requires_authentication(): void
    {
        $this->getJson('/api/wishlist')->assertUnauthorized();
        $this->postJson('/api/wishlist', ['places_id' => 1])->assertUnauthorized();
    }
}
