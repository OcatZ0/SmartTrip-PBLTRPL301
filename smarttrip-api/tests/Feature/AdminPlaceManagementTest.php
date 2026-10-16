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
            'external_place_id' => uniqid('gp-'), 'business_status' => 'operational',
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
        $this->makePlace(['name' => 'Dari Manual', 'source' => 'manual', 'external_place_id' => null]);

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertOk();
        $response->assertSee('Dari Google');
        $response->assertSee('Dari Manual');
    }

    public function test_the_list_can_be_searched_by_name(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Pantai Melur']);
        $this->makePlace(['name' => 'Kafe Tepi Laut', 'external_place_id' => 'gp-2']);

        $response = $this->actingAs($admin)->get('/admin/places?search=pantai');

        $response->assertOk();
        $response->assertSee('Pantai Melur');
        $response->assertDontSee('Kafe Tepi Laut');
    }

    public function test_the_list_can_be_filtered_by_kecamatan(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Nongsa Punya', 'kecamatan' => 'Nongsa']);
        $this->makePlace(['name' => 'Sekupang Punya', 'kecamatan' => 'Sekupang', 'external_place_id' => 'gp-2']);

        $response = $this->actingAs($admin)->get('/admin/places?kecamatan=Sekupang');

        $response->assertOk();
        $response->assertSee('Sekupang Punya');
        $response->assertDontSee('Nongsa Punya');
    }

    // --- create (manual add) ---

    public function test_the_list_links_to_the_edit_page_and_confirms_deletes_in_a_modal(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertOk();
        $response->assertSee('href="'.route('admin.places.edit', $place).'"', false);
        $response->assertSee('data-confirm-url="'.route('admin.places.destroy', $place).'"', false);
        $response->assertSee('id="confirmModal"', false);
        $response->assertDontSee('modalEditTempat');
    }

    public function test_the_list_pagination_has_no_english_summary(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        foreach (range(1, 8) as $number) {
            $this->makePlace(['name' => "Tempat {$number}"]);
        }

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertOk();
        $response->assertSee('aria-label="Halaman berikutnya"', false);
        $response->assertDontSee('Showing');
    }

    public function test_the_list_shows_no_made_up_rating(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Tanpa Rating', 'rating' => null, 'review_count' => 0]);

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertOk();
        $response->assertSee('Belum ada rating');
        $response->assertDontSee('4,5');
    }

    public function test_the_list_shows_the_source_rating_with_its_review_count(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['rating' => 4.3, 'review_count' => 120]);

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertSee('4,3');
        $response->assertSee('(120 ulasan)');
    }

    public function test_the_list_shows_three_categories_and_counts_the_rest(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();
        foreach (['Pantai', 'Sejarah', 'Alam', 'Keluarga', 'Foto'] as $name) {
            $category = Category::create(['name_id' => $name, 'name_en' => $name, 'slug' => strtolower($name)]);
            $place->categories()->attach($category->categories_id);
        }

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertSee('+2');
        $response->assertSee('title="', false);
    }

    public function test_the_list_shows_the_cost(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Hotel AI', 'type' => 'lodging', 'estimated_cost_idr' => 350000]);

        $response = $this->actingAs($admin)->get('/admin/places');

        $response->assertSee('Rp 350.000');
        $response->assertSee('per malam');
        $response->assertDontSee('Perkiraan AI');
    }

    public function test_an_admin_can_add_a_manual_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->post('/admin/places', [
            'name' => 'Warung Baru', 'type' => 'culinary', 'lat' => 1.1, 'lng' => 104.1,
            'address' => 'Batam Kota', 'kecamatan' => 'Batam Kota',
        ]);

        $response->assertRedirect();
        $this->assertDatabaseHas('places', [
            'name' => 'Warung Baru', 'source' => 'manual', 'business_status' => 'operational', 'external_place_id' => null,
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

    public function test_the_edit_page_checkbox_can_leave_the_category_tags_unreviewed(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['category_tags_reviewed' => false]);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", ['category_tags_reviewed' => '0'])->assertRedirect();

        $this->assertFalse($place->fresh()->category_tags_reviewed);
    }

    public function test_emptying_the_description_falls_back_to_the_generated_one(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['description_override' => 'Teks admin lama', 'description_en' => 'Old English text']);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", ['description_override' => '', 'description_en' => ''])->assertRedirect();

        $place->refresh();
        $this->assertNull($place->description_override);
        $this->assertNull($place->description_en);
    }

    public function test_the_edit_page_shows_the_curation_form_completeness_and_save_bar(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['name' => 'Jembatan Barelang', 'estimated_cost_idr' => 0, 'estimated_visit_minutes' => 60, 'category_tags_reviewed' => false]);

        $response = $this->actingAs($admin)->get(route('admin.places.edit', $place));

        $response->assertOk();
        $response->assertSeeInOrder(['Edit tempat', 'Aktif di katalog', 'Jembatan Barelang', 'Data kurasi', 'Biaya masuk per orang', 'Kategori', 'Kata Kunci Pencarian', 'Deskripsi']);
        $response->assertSeeInOrder(['Kelengkapan', '2 / 6', 'Gratis', '60 menit', 'Belum', 'Popularitas', 'Disimpan ke wishlist', 'Masuk itinerary']);
        $response->assertSee('name="search_keywords"', false);
        $response->assertSee('name="category_tags_reviewed"', false);
        $response->assertSeeInOrder(['class="pe-savebar"', 'Hapus dari katalog', 'Batal', 'form="formEditPlace"', 'Simpan perubahan'], false);
    }

    public function test_the_edit_page_confirms_deletes_in_the_shared_modal(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace();

        $response = $this->actingAs($admin)->get(route('admin.places.edit', $place));

        $response->assertOk();
        $response->assertSee('data-confirm-url="'.route('admin.places.destroy', $place).'"', false);
        $response->assertSee('id="confirmModal"', false);
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
