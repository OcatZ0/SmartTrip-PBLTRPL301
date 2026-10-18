<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlacePhoto;
use App\Models\PlaceReview;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PlaceCatalogTest extends TestCase
{
    use RefreshDatabase;

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'google', 'external_place_id' => uniqid('gp-'),
        ], $overrides));
    }

    // --- F005: katalog ---

    public function test_the_catalog_is_public_and_lists_places(): void
    {
        $this->makePlace(['name' => 'Pantai Melur']);
        $this->makePlace(['name' => 'Kafe Tepi Laut', 'external_place_id' => 'gp-2']);

        $response = $this->getJson('/api/places');

        $response->assertOk();
        $this->assertCount(2, $response->json('data'));
    }

    public function test_the_catalog_excludes_places_deleted_from_it(): void
    {
        $this->makePlace(['name' => 'Tempat Tutup'])->delete();
        $this->makePlace(['name' => 'Tempat Buka', 'external_place_id' => 'gp-open']);

        $response = $this->getJson('/api/places');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Tempat Buka', $response->json('data.0.name'));
    }

    public function test_the_catalog_can_be_searched_by_name_case_insensitively(): void
    {
        $this->makePlace(['name' => 'Pantai Melur']);
        $this->makePlace(['name' => 'Kafe Tepi Laut', 'external_place_id' => 'gp-2']);

        $response = $this->getJson('/api/places?search=PANTAI');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Pantai Melur', $response->json('data.0.name'));
    }

    public function test_the_catalog_can_be_filtered_by_category_slug(): void
    {
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $culinary = Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);

        $beachPlace = $this->makePlace(['name' => 'Pantai Melur']);
        $beachPlace->categories()->attach($beach->categories_id);

        $cafePlace = $this->makePlace(['name' => 'Kafe Tepi Laut', 'external_place_id' => 'gp-2']);
        $cafePlace->categories()->attach($culinary->categories_id);

        $response = $this->getJson('/api/places?category=pantai');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Pantai Melur', $response->json('data.0.name'));
    }

    public function test_the_catalog_can_be_filtered_by_kecamatan(): void
    {
        $this->makePlace(['name' => 'A', 'kecamatan' => 'Nongsa']);
        $this->makePlace(['name' => 'B', 'kecamatan' => 'Batam Kota', 'external_place_id' => 'gp-2']);

        $response = $this->getJson('/api/places?kecamatan=nongsa');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('A', $response->json('data.0.name'));
    }

    public function test_the_kecamatan_list_counts_open_places_and_merges_spelling_variants(): void
    {
        $this->makePlace(['name' => 'A', 'kecamatan' => 'Nongsa']);
        $this->makePlace(['name' => 'B', 'kecamatan' => 'nongsa ', 'external_place_id' => 'gp-2']);
        $this->makePlace(['name' => 'C', 'kecamatan' => 'Batam Kota', 'external_place_id' => 'gp-3']);
        $this->makePlace(['name' => 'D', 'kecamatan' => 'Galang', 'external_place_id' => 'gp-4'])->delete();
        $this->makePlace(['name' => 'E', 'kecamatan' => null, 'external_place_id' => 'gp-5']);

        $response = $this->getJson('/api/places/kecamatan');

        $response->assertOk()->assertExactJson(['data' => [
            ['name' => 'Batam Kota', 'places_count' => 1],
            ['name' => 'Nongsa', 'places_count' => 2],
        ]]);
    }

    public function test_a_non_numeric_place_id_is_a_404(): void
    {
        $this->getJson('/api/places/abc')->assertNotFound();
    }

    public function test_the_catalog_can_be_filtered_by_type(): void
    {
        $this->makePlace(['name' => 'Hotel Harbour Bay', 'type' => 'lodging']);
        $this->makePlace(['name' => 'Pantai Melur', 'external_place_id' => 'gp-2']);

        $response = $this->getJson('/api/places?type=lodging');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Hotel Harbour Bay', $response->json('data.0.name'));
    }

    public function test_the_category_list_is_public_and_excludes_soft_deleted_categories(): void
    {
        Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        Category::create(['name_id' => 'Kuliner', 'name_en' => 'Culinary', 'slug' => 'kuliner']);
        Category::create(['name_id' => 'Lama', 'name_en' => 'Old', 'slug' => 'lama'])->delete();

        $response = $this->getJson('/api/categories');

        $response->assertOk();
        $this->assertSame(['Kuliner', 'Pantai'], array_column($response->json('data'), 'name_id'));
    }

    public function test_the_catalog_is_paginated(): void
    {
        for ($number = 0; $number < 25; $number++) {
            $this->makePlace(['name' => "Tempat $number", 'external_place_id' => "gp-$number"]);
        }

        $response = $this->getJson('/api/places?per_page=10');

        $response->assertOk();
        $this->assertCount(10, $response->json('data'));
        $this->assertSame(25, $response->json('meta.total'));
        $this->assertSame(3, $response->json('meta.last_page'));
    }

    public function test_a_soft_deleted_place_is_excluded_from_the_catalog(): void
    {
        $place = $this->makePlace();
        $place->delete();

        $response = $this->getJson('/api/places');

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    // --- rating blend ---

    public function test_rating_is_the_average_of_the_in_app_reviews(): void
    {
        $place = $this->makePlace(['name' => 'A']);
        foreach ([3, 5] as $rating) {
            PlaceReview::create(['places_id' => $place->places_id, 'users_id' => User::factory()->create()->users_id, 'rating' => $rating]);
        }

        $response = $this->getJson('/api/places');

        $response->assertOk();
        $this->assertEquals(4.0, $response->json('data.0.rating'));
        $this->assertSame(2, $response->json('data.0.review_count_in_app'));
        $response->assertJsonMissingPath('data.0.rating_google');
        $response->assertJsonMissingPath('data.0.price_level');
    }

    public function test_rating_is_null_when_there_is_no_data_at_all(): void
    {
        $this->makePlace(['name' => 'A']);

        $response = $this->getJson('/api/places');

        $response->assertOk();
        $this->assertNull($response->json('data.0.rating'));
    }

    // --- F006: detail ---

    public function test_the_detail_endpoint_is_public_and_returns_full_place_info(): void
    {
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $place = $this->makePlace([
            'name' => 'Pantai Melur', 'description_id' => 'Deskripsi asli Google',
            'description_override' => 'Deskripsi versi admin', 'description_en' => 'Admin English description',
            'estimated_visit_minutes' => 90,
        ]);
        $place->categories()->attach($category->categories_id);
        PlacePhoto::create(['places_id' => $place->places_id, 'photo_url' => 'foto-2.jpg', 'sort_order' => 1]);
        PlacePhoto::create(['places_id' => $place->places_id, 'photo_url' => 'foto-1.jpg', 'sort_order' => 0]);

        $response = $this->getJson("/api/places/{$place->places_id}");

        $response->assertOk();
        $response->assertJsonPath('data.places_id', $place->places_id);
        $response->assertJsonPath('data.description_id', 'Deskripsi versi admin');
        $response->assertJsonPath('data.description_en', 'Admin English description');
        $response->assertJsonPath('data.photos.0.url', 'foto-1.jpg');
        $response->assertJsonPath('data.photos.1.url', 'foto-2.jpg');
        $response->assertJsonMissingPath('data.photos.0.credit');
        $response->assertJsonPath('data.categories.0.slug', 'pantai');
        $response->assertJsonPath('data.estimated_visit_minutes', 90);
    }

    public function test_the_detail_description_falls_back_to_the_google_description_without_admin_override(): void
    {
        $place = $this->makePlace(['description_id' => 'Deskripsi asli Google', 'description_override' => null]);

        $response = $this->getJson("/api/places/{$place->places_id}");

        $response->assertOk();
        $response->assertJsonPath('data.description_id', 'Deskripsi asli Google');
    }

    public function test_the_detail_opening_hours_are_lines_made_from_the_hours_per_day(): void
    {
        $place = $this->makePlace(['opening_hours' => ['sun' => [], 'mon' => [['09:00', '19:00']]]]);
        $without = $this->makePlace(['name' => 'Tanpa Jam', 'external_place_id' => 'gp-no-hours', 'opening_hours' => null]);

        $this->getJson("/api/places/{$place->places_id}")
            ->assertOk()
            ->assertJsonPath('data.opening_hours', ['weekday_descriptions' => ['Senin: 09.00–19.00', 'Minggu: Tutup']]);
        $this->getJson("/api/places/{$without->places_id}")->assertJsonPath('data.opening_hours', null);
    }

    public function test_the_detail_endpoint_404s_for_a_missing_place(): void
    {
        $response = $this->getJson('/api/places/99999');

        $response->assertNotFound();
    }

    public function test_the_detail_endpoint_404s_for_a_soft_deleted_place(): void
    {
        $place = $this->makePlace();
        $place->delete();

        $response = $this->getJson("/api/places/{$place->places_id}");

        $response->assertNotFound();
    }
}
