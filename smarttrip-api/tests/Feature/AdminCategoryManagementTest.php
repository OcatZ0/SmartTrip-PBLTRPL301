<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\Place;
use App\Models\Trip;
use Tests\TestCase;

class AdminCategoryManagementTest extends TestCase
{
    use RefreshDatabase;

    // --- access control ---

    public function test_a_guest_is_redirected_to_login(): void
    {
        $response = $this->get('/admin/categories');

        $response->assertRedirect('/admin/login');
    }

    public function test_a_non_admin_user_is_forbidden(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->get('/admin/categories');

        $response->assertForbidden();
    }

    // --- list ---

    public function test_the_list_shows_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($admin)->get('/admin/categories');

        $response->assertOk();
        $response->assertSee('Pantai');
    }

    // --- create ---

    public function test_an_admin_can_create_a_category_with_an_auto_generated_slug(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->post('/admin/categories', [
            'name_id' => 'Wisata Kuliner', 'name_en' => 'Culinary Tourism',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('categories', ['name_id' => 'Wisata Kuliner', 'slug' => 'wisata-kuliner']);
    }

    public function test_an_admin_can_create_a_category_with_a_custom_slug(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin)->post('/admin/categories', [
            'name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'beach-pantai',
        ])->assertRedirect();

        $this->assertDatabaseHas('categories', ['slug' => 'beach-pantai']);
    }

    public function test_creating_a_category_requires_name_id_and_name_en(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->post('/admin/categories', []);

        $response->assertSessionHasErrors(['name_id', 'name_en']);
    }

    public function test_a_duplicate_slug_is_rejected(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($admin)->post('/admin/categories', [
            'name_id' => 'Wisata Pantai', 'name_en' => 'Beach Tourism', 'slug' => 'pantai',
        ]);

        $response->assertSessionHasErrors(['slug']);
    }

    public function test_the_slug_of_a_soft_deleted_category_can_be_reused(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $old = Category::create(['name_id' => 'Pantai Lama', 'name_en' => 'Old Beach', 'slug' => 'pantai']);
        $old->delete();

        $response = $this->actingAs($admin)->post('/admin/categories', [
            'name_id' => 'Pantai Baru', 'name_en' => 'New Beach', 'slug' => 'pantai',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('categories', ['name_id' => 'Pantai Baru', 'slug' => 'pantai']);
    }

    public function test_a_non_admin_cannot_create_a_category(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->post('/admin/categories', [
            'name_id' => 'Pantai', 'name_en' => 'Beach',
        ]);

        $response->assertForbidden();
        $this->assertDatabaseMissing('categories', ['name_id' => 'Pantai']);
    }

    // --- update ---

    public function test_an_admin_can_update_a_category(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($admin)->put("/admin/categories/{$category->categories_id}", [
            'name_id' => 'Pantai & Laut', 'name_en' => 'Beach & Sea', 'slug' => 'pantai-laut',
        ]);

        $response->assertRedirect();
        $category->refresh();
        $this->assertSame('Pantai & Laut', $category->name_id);
        $this->assertSame('pantai-laut', $category->slug);
    }

    public function test_updating_a_category_keeping_its_own_slug_is_not_rejected_as_a_duplicate(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($admin)->put("/admin/categories/{$category->categories_id}", [
            'name_id' => 'Pantai Diperbarui', 'name_en' => 'Beach', 'slug' => 'pantai',
        ]);

        $response->assertRedirect();
        $this->assertSame('Pantai Diperbarui', $category->fresh()->name_id);
    }

    public function test_updating_a_category_to_another_categorys_slug_is_rejected(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);

        $response = $this->actingAs($admin)->put("/admin/categories/{$culinary->categories_id}", [
            'name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'pantai',
        ]);

        $response->assertSessionHasErrors(['slug']);
    }

    public function test_a_non_admin_cannot_update_a_category(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($user)->put("/admin/categories/{$category->categories_id}", [
            'name_id' => 'Diubah', 'name_en' => 'Changed', 'slug' => 'pantai',
        ]);

        $response->assertForbidden();
        $this->assertSame('Pantai', $category->fresh()->name_id);
    }

    // --- delete ---

    public function test_an_admin_can_delete_a_category(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($admin)->delete("/admin/categories/{$category->categories_id}");

        $response->assertRedirect();
        $this->assertSoftDeleted($category);
    }

    public function test_a_deleted_category_no_longer_appears_in_the_list(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $category->delete();

        $response = $this->actingAs($admin)->get('/admin/categories');

        $response->assertOk();
        $response->assertDontSee('Pantai');
    }

    public function test_a_non_admin_cannot_delete_a_category(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $response = $this->actingAs($user)->delete("/admin/categories/{$category->categories_id}");

        $response->assertForbidden();
        $this->assertDatabaseHas('categories', ['categories_id' => $category->categories_id, 'deleted_at' => null]);
    }

    // --- activity log (F023 groundwork) ---

    public function test_updating_a_category_records_an_activity_log_entry_with_the_admin_as_causer(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $this->actingAs($admin)->put("/admin/categories/{$category->categories_id}", [
            'name_id' => 'Pantai & Laut', 'name_en' => 'Beach & Sea', 'slug' => 'pantai-laut',
        ])->assertRedirect();

        $this->assertDatabaseHas('activity_log', [
            'subject_type' => Category::class,
            'subject_id' => $category->categories_id,
            'causer_id' => $admin->users_id,
            'event' => 'updated',
        ]);
    }

    // --- delete guard (PRD audit 2026-10-10: RESTRICT does not cover soft delete) ---

    public function test_a_category_still_used_by_a_place_cannot_be_deleted(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $place = Place::create(['name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.0, 'address' => 'Nongsa', 'source' => 'manual']);
        $place->categories()->attach($category->categories_id);

        $response = $this->actingAs($admin)->delete("/admin/categories/{$category->categories_id}");

        $response->assertRedirect(route('admin.categories.index'));
        $response->assertSessionHas('error');
        $this->assertDatabaseHas('categories', ['categories_id' => $category->categories_id, 'deleted_at' => null]);
    }

    public function test_a_category_still_used_by_a_trip_cannot_be_deleted(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $owner = User::factory()->create();
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $trip = Trip::create(['users_id' => $owner->users_id, 'title' => 'Trip', 'num_days' => 1, 'budget_total' => 100000, 'start_date' => now()->toDateString()]);
        $trip->interestCategories()->attach($category->categories_id);

        $response = $this->actingAs($admin)->delete("/admin/categories/{$category->categories_id}");

        $response->assertSessionHas('error');
        $this->assertDatabaseHas('categories', ['categories_id' => $category->categories_id, 'deleted_at' => null]);
    }
}
