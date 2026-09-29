<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfilePreferencesTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    public function test_a_new_user_has_no_default_preferences_yet(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeader($user))->getJson('/api/profile/preferences');

        $response->assertOk();
        $response->assertJsonPath('categories', []);
        $response->assertJsonPath('default_weight_kategori', null);
    }

    public function test_getting_preferences_requires_authentication(): void
    {
        $response = $this->getJson('/api/profile/preferences');

        $response->assertUnauthorized();
    }

    public function test_a_user_can_set_default_preferences(): void
    {
        $user = User::factory()->create();
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);

        $response = $this->withHeaders($this->authHeader($user))->putJson('/api/profile/preferences', [
            'category_ids' => [$beach->categories_id, $culinary->categories_id],
            'rating_kategori' => 8, 'rating_jarak' => 4, 'rating_anggaran' => 4, 'rating_rating' => 4,
        ]);

        $response->assertOk();
        $this->assertEqualsWithDelta(0.4, $response->json('default_weight_kategori'), 0.001);
        $this->assertEqualsWithDelta(0.2, $response->json('default_weight_jarak'), 0.001);
        $this->assertCount(2, $response->json('categories'));

        $user->refresh();
        $this->assertEqualsWithDelta(0.4, (float) $user->default_weight_kategori, 0.001);
        $this->assertCount(2, $user->defaultInterestCategories);
    }

    public function test_all_ratings_zero_defaults_to_equal_shares(): void
    {
        $user = User::factory()->create();
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->withHeaders($this->authHeader($user))->putJson('/api/profile/preferences', [
            'category_ids' => [$category->categories_id],
            'rating_kategori' => 0, 'rating_jarak' => 0, 'rating_anggaran' => 0, 'rating_rating' => 0,
        ]);

        $response->assertOk();
        $this->assertEqualsWithDelta(0.25, $response->json('default_weight_kategori'), 0.001);
        $this->assertEqualsWithDelta(0.25, $response->json('default_weight_rating'), 0.001);
    }

    public function test_updating_preferences_replaces_the_previous_categories(): void
    {
        $user = User::factory()->create();
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);
        $headers = $this->authHeader($user);

        $this->withHeaders($headers)->putJson('/api/profile/preferences', [
            'category_ids' => [$beach->categories_id],
            'rating_kategori' => 5, 'rating_jarak' => 5, 'rating_anggaran' => 5, 'rating_rating' => 5,
        ])->assertOk();

        $response = $this->withHeaders($headers)->putJson('/api/profile/preferences', [
            'category_ids' => [$culinary->categories_id],
            'rating_kategori' => 5, 'rating_jarak' => 5, 'rating_anggaran' => 5, 'rating_rating' => 5,
        ]);

        $response->assertOk();
        $this->assertCount(1, $response->json('categories'));
        $this->assertSame('kuliner', $response->json('categories.0.slug'));
    }

    public function test_at_least_one_category_is_required(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeader($user))->putJson('/api/profile/preferences', [
            'category_ids' => [],
            'rating_kategori' => 5, 'rating_jarak' => 5, 'rating_anggaran' => 5, 'rating_rating' => 5,
        ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['category_ids']);
    }

    public function test_a_nonexistent_category_id_is_rejected(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeader($user))->putJson('/api/profile/preferences', [
            'category_ids' => [99999],
            'rating_kategori' => 5, 'rating_jarak' => 5, 'rating_anggaran' => 5, 'rating_rating' => 5,
        ]);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['category_ids.0']);
    }

    public function test_setting_preferences_only_affects_the_authenticated_user(): void
    {
        $userA = User::factory()->create();
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $this->withHeaders($this->authHeader($userA))->putJson('/api/profile/preferences', [
            'category_ids' => [$category->categories_id],
            'rating_kategori' => 5, 'rating_jarak' => 5, 'rating_anggaran' => 5, 'rating_rating' => 5,
        ])->assertOk();

        $this->assertCount(0, User::factory()->create()->defaultInterestCategories);
    }
}
