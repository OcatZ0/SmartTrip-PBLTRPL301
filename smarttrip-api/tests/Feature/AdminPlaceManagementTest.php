<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminPlaceManagementTest extends TestCase
{
    use RefreshDatabase;

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'kecamatan' => 'Nongsa', 'source' => 'google',
            'google_place_id' => uniqid('gp-'), 'business_status' => 'operational',
        ], $overrides));
    }

    // --- access control ---

    public function test_a_guest_is_redirected_to_login(): void
    {
        $response = $this->get('/admin/places');

        $response->assertRedirect('/admin/login');
    }

    public function test_a_non_admin_user_is_forbidden(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->get('/admin/places');

        $response->assertForbidden();
    }

    // --- list/search ---

    public function test_the_list_shows_places_from_both_google_and_manual_sources(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Dari Google', 'source' => 'google']);
        $this->makePlace(['name' => 'Dari Manual', 'source' => 'manual', 'google_place_id' => null]);

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertOk();
        $response->assertSee('Dari Google');
        $response->assertSee('Dari Manual');
    }

    public function test_the_list_can_be_searched_by_name(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Pantai Melur']);
        $this->makePlace(['name' => 'Kafe Tepi Laut', 'google_place_id' => 'gp-2']);

        $response = $this->actingAs($admin)->get('/admin/places?search=pantai');

        $response->assertOk();
        $response->assertSee('Pantai Melur');
        $response->assertDontSee('Kafe Tepi Laut');
    }

    public function test_the_list_can_be_filtered_by_kecamatan(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Nongsa Punya', 'kecamatan' => 'Nongsa']);
        $this->makePlace(['name' => 'Sekupang Punya', 'kecamatan' => 'Sekupang', 'google_place_id' => 'gp-2']);

        $response = $this->actingAs($admin)->get('/admin/places?kecamatan=Sekupang');

        $response->assertOk();
        $response->assertSee('Sekupang Punya');
        $response->assertDontSee('Nongsa Punya');
    }

    // --- create (manual add) ---

    public function test_an_admin_can_add_a_manual_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->post('/admin/places', [
            'name' => 'Warung Baru', 'type' => 'culinary', 'lat' => 1.1, 'lng' => 104.1,
            'address' => 'Batam Kota', 'kecamatan' => 'Batam Kota',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('places', [
            'name' => 'Warung Baru', 'source' => 'manual', 'business_status' => 'operational', 'google_place_id' => null,
        ]);
    }

    public function test_adding_a_manual_place_requires_the_core_fields(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->post('/admin/places', ['name' => '']);

        $response->assertSessionHasErrors(['name', 'type', 'lat', 'lng', 'address']);
    }

    public function test_a_non_admin_cannot_add_a_manual_place(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->post('/admin/places', [
            'name' => 'Warung Baru', 'type' => 'culinary', 'lat' => 1.1, 'lng' => 104.1, 'address' => 'Batam Kota',
        ]);

        $response->assertForbidden();
        $this->assertDatabaseMissing('places', ['name' => 'Warung Baru']);
    }

    // --- update (curated fields) ---

    public function test_an_admin_can_edit_curated_fields(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();

        $response = $this->actingAs($admin)->put("/admin/places/{$place->places_id}", [
            'kecamatan' => 'Batam Kota',
            'description_override' => 'Deskripsi baru dari admin',
            'description_en' => 'New admin description',
            'estimated_cost_idr' => 50000,
            'estimated_visit_minutes' => 90,
            'is_outdoor' => '1',
        ]);

        $response->assertRedirect();
        $place->refresh();
        $this->assertSame('Batam Kota', $place->kecamatan);
        $this->assertSame('Deskripsi baru dari admin', $place->description_override);
        $this->assertSame(50000, $place->estimated_cost_idr);
        $this->assertSame(90, $place->estimated_visit_minutes);
        $this->assertTrue($place->is_outdoor);
    }

    public function test_editing_a_place_syncs_its_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);
        $place->categories()->attach($culinary->categories_id);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", [
            'category_ids' => [$beach->categories_id],
        ])->assertRedirect();

        $place->refresh();
        $this->assertTrue($place->categories->contains('categories_id', $beach->categories_id));
        $this->assertFalse($place->categories->contains('categories_id', $culinary->categories_id));
    }

    public function test_editing_a_place_marks_its_category_tags_as_reviewed(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['category_tags_reviewed' => false]);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", [])->assertRedirect();

        $this->assertTrue($place->fresh()->category_tags_reviewed);
    }

    public function test_editing_a_place_without_category_ids_clears_its_categories(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $place->categories()->attach($beach->categories_id);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", [])->assertRedirect();

        $this->assertCount(0, $place->fresh()->categories);
    }

    public function test_a_non_admin_cannot_edit_a_place(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $place = $this->makePlace(['kecamatan' => 'Nongsa']);

        $response = $this->actingAs($user)->put("/admin/places/{$place->places_id}", ['kecamatan' => 'Batam Kota']);

        $response->assertForbidden();
        $this->assertSame('Nongsa', $place->fresh()->kecamatan);
    }

    // --- delete ---

    public function test_an_admin_can_delete_a_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();

        $response = $this->actingAs($admin)->delete("/admin/places/{$place->places_id}");

        $response->assertRedirect();
        $this->assertSoftDeleted($place);
    }

    public function test_a_deleted_place_can_no_longer_be_edited(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();
        $place->delete();

        $response = $this->actingAs($admin)->get("/admin/places/{$place->places_id}/edit");

        $response->assertNotFound();
    }

    // --- activity log (F023 groundwork) ---

    public function test_editing_a_place_records_an_activity_log_entry_with_the_admin_as_causer(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['kecamatan' => 'Nongsa']);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", ['kecamatan' => 'Batam Kota'])->assertRedirect();

        $this->assertDatabaseHas('activity_log', [
            'subject_type' => Place::class,
            'subject_id' => $place->places_id,
            'causer_type' => User::class,
            'causer_id' => $admin->users_id,
            'event' => 'updated',
        ]);
    }

    public function test_creating_a_manual_place_does_not_require_a_prior_activity_log_entry_to_exist(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin)->post('/admin/places', [
            'name' => 'Warung Baru', 'type' => 'culinary', 'lat' => 1.1, 'lng' => 104.1, 'address' => 'Batam Kota',
        ])->assertRedirect();

        $this->assertDatabaseHas('activity_log', ['event' => 'created', 'causer_id' => $admin->users_id]);
    }
}
