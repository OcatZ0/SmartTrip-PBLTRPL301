<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlaceReview;
use App\Models\Trip;
use App\Models\TripWishlistPlace;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Nongsa, Batam', 'source' => 'manual', 'business_status' => 'operational',
        ], $overrides));
    }

    // --- access control ---

    public function test_a_guest_is_redirected_to_login(): void
    {
        $response = $this->get('/admin/dashboard');

        $response->assertRedirect('/admin/login');
    }

    public function test_a_non_admin_user_is_forbidden(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->get('/admin/dashboard');

        $response->assertForbidden();
    }

    // --- empty state ---

    public function test_the_dashboard_renders_an_empty_state_before_any_bootstrap_data_exists(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Belum pernah dijalankan');
        $response->assertSee('Belum ada data wishlist.');
    }

    // --- pending candidates + sync status ---

    public function test_it_shows_the_number_of_pending_candidates(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        PlaceCandidate::create(['external_place_id' => 'gp-1', 'name' => 'A', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'pending']);
        PlaceCandidate::create(['external_place_id' => 'gp-2', 'name' => 'B', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'rejected']);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('1', false);
    }

    public function test_it_shows_the_last_discovery_timestamp_from_the_newest_candidate(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = PlaceCandidate::create(['external_place_id' => 'gp-1', 'name' => 'A', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'pending']);
        $candidate->forceFill(['created_at' => '2026-05-10 08:00:00'])->save();

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('2026-05-10');
    }

    public function test_it_shows_the_last_enrichment_timestamp_from_the_newest_google_sourced_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['source' => 'google', 'external_place_id' => 'gp-1']);
        $place->forceFill(['created_at' => '2026-06-15 10:00:00'])->save();
        // Manual place tidak dihitung sebagai enrichment.
        $manual = $this->makePlace(['source' => 'manual', 'external_place_id' => null]);
        $manual->forceFill(['created_at' => '2026-08-01 10:00:00'])->save();

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('2026-06-15');
        $response->assertDontSee('2026-08-01');
    }

    // --- quota ---

    public function test_it_shows_the_geoapify_credits_spent_today_against_the_daily_limit(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Cache::put('geoapify:credits:'.now()->toDateString(), 42);
        Cache::put('geoapify:credits:'.now()->subDay()->toDateString(), 900);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Kredit Geoapify Hari Ini');
        $response->assertSee('42 / 3000');
    }

    // --- attention lists ---

    public function test_it_counts_places_missing_estimated_cost(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Tanpa Biaya', 'estimated_cost_idr' => null]);
        $this->makePlace(['name' => 'Ada Biaya', 'external_place_id' => 'gp-2', 'estimated_cost_idr' => 50000]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('1 belum ada estimasi biaya');
    }

    public function test_it_counts_places_with_unreviewed_category_tags(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Belum Direview', 'category_tags_reviewed' => false]);
        $this->makePlace(['name' => 'Sudah Direview', 'external_place_id' => 'gp-2', 'category_tags_reviewed' => true]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('1 hasil AI (deskripsi/tag) belum direview');
    }

    // --- analytics ---

    public function test_it_lists_the_most_wishlisted_places_in_order(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $owner = User::factory()->create();
        $trip = Trip::create(['users_id' => $owner->users_id, 'title' => 'T', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);
        $popular = $this->makePlace(['name' => 'Populer']);
        $lessPopular = $this->makePlace(['name' => 'Kurang Populer', 'external_place_id' => 'gp-2']);
        $untouched = $this->makePlace(['name' => 'Tidak Pernah Diwishlist', 'external_place_id' => 'gp-3']);

        $anotherTrip = Trip::create(['users_id' => $owner->users_id, 'title' => 'T2', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);
        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $popular->places_id]);
        TripWishlistPlace::create(['trips_id' => $anotherTrip->trips_id, 'places_id' => $popular->places_id]);
        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $lessPopular->places_id]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Populer', 'Kurang Populer']);
        $response->assertDontSee('Tidak Pernah Diwishlist');
    }

    public function test_it_shows_the_average_in_app_rating(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $reviewer = User::factory()->create();
        $place = $this->makePlace();
        PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $reviewer->users_id, 'rating' => 4]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('4.00');
    }

    public function test_it_shows_the_trip_volume(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $owner = User::factory()->create();
        Trip::create(['users_id' => $owner->users_id, 'title' => 'T1', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);
        Trip::create(['users_id' => $owner->users_id, 'title' => 'T2', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('2', false);
    }
}
