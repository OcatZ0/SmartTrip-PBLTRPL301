<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class AdminActivityLogTest extends TestCase
{
    use RefreshDatabase;

    // --- places ---

    public function test_the_place_edit_page_shows_the_creation_entry(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'manual',
        ]);

        $response = $this->actingAs($admin)->get("/admin/places/{$place->places_id}/edit");

        $response->assertOk();
        $response->assertSee('Riwayat Perubahan');
        $response->assertSee('Ditambahkan');
        $response->assertSee('Pantai Melur');
    }

    public function test_the_place_edit_page_shows_old_and_new_values_after_an_update(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'kecamatan' => 'Nongsa', 'source' => 'manual',
        ]);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", ['kecamatan' => 'Batam Kota'])->assertRedirect();

        $response = $this->actingAs($admin)->get("/admin/places/{$place->places_id}/edit");

        $response->assertOk();
        $response->assertSee('Nongsa');
        $response->assertSee('Batam Kota');
        $response->assertSee('Diubah');
    }

    public function test_the_place_edit_page_shows_which_admin_made_the_change(): void
    {
        $admin = User::factory()->create(['role' => 'admin', 'name' => 'Admin Satu']);
        $place = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'manual',
        ]);

        $this->actingAs($admin)->put("/admin/places/{$place->places_id}", ['kecamatan' => 'Batam Kota'])->assertRedirect();

        $response = $this->actingAs($admin)->get("/admin/places/{$place->places_id}/edit");

        $response->assertOk();
        $response->assertSee('Admin Satu');
    }

    public function test_the_place_edit_page_shows_an_empty_state_when_there_is_no_history(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        // Insert lewat query builder langsung - bypass Eloquent events,
        // jadi memang tidak ada baris activity_log sama sekali buat baris ini.
        $placesId = DB::table('places')->insertGetId([
            'name' => 'Tanpa Riwayat', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'manual',
            'category_tags_reviewed' => false,
            'created_at' => now(),
        ], 'places_id');

        $response = $this->actingAs($admin)->get("/admin/places/{$placesId}/edit");

        $response->assertOk();
        $response->assertSee('Belum ada riwayat perubahan');
    }

    // --- categories ---

    public function test_the_category_history_shows_the_creation_and_update_entries(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);

        $this->actingAs($admin)->put("/admin/categories/{$category->categories_id}", [
            'name_id' => 'Pantai & Laut', 'name_en' => 'Beach & Sea', 'slug' => 'pantai',
        ])->assertRedirect();

        // The category edit popup on the list loads its history from here.
        $response = $this->actingAs($admin)->getJson("/admin/categories/{$category->categories_id}/activities");

        $response->assertOk();
        $response->assertJsonPath('subject', 'Pantai & Laut');
        // Both entries share a timestamp here, so their order is not fixed.
        $activities = collect($response->json('activities'));
        $this->assertEqualsCanonicalizing(['created', 'updated'], $activities->pluck('event')->all());
        $updated = $activities->firstWhere('event', 'updated');
        $this->assertSame('Pantai', $updated['old']['name_id']);
        $this->assertSame('Pantai & Laut', $updated['attributes']['name_id']);
    }

    public function test_a_non_admin_cannot_view_a_places_edit_page_or_its_history(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $place = Place::create([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'manual',
        ]);

        $response = $this->actingAs($user)->get("/admin/places/{$place->places_id}/edit");

        $response->assertForbidden();
    }
}
