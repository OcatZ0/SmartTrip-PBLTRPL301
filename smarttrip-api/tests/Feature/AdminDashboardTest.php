<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlaceReview;
use App\Models\Trip;
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
        $response->assertSee('Discovery belum pernah dijalankan');
        $response->assertSee('Tidak ada yang perlu dikerjakan.');
    }

    // --- pending candidates + sync status ---

    public function test_it_lists_pending_candidates_and_counts_them(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        PlaceCandidate::create(['external_place_id' => 'osm:n1', 'name' => 'Kandidat Pending', 'type' => 'culinary', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'pending']);
        PlaceCandidate::create(['external_place_id' => 'osm:n2', 'name' => 'Kandidat Ditolak', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'rejected']);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Kandidat menunggu', '1', 'Perlu direview']);
        $response->assertSeeInOrder(['Kandidat baru', 'Kandidat Pending', 'Nongsa · dari Geoapify', 'Kuliner', 'Review']);
        $response->assertDontSee('Kandidat Ditolak');
    }

    public function test_it_shows_the_last_discovery_timestamp_from_the_newest_candidate(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = PlaceCandidate::create(['external_place_id' => 'osm:n1', 'name' => 'A', 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'pending']);
        $candidate->forceFill(['created_at' => '2026-05-10 08:00:00'])->save();

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Discovery terakhir '.$candidate->fresh()->created_at->translatedFormat('j M Y, H.i'));
    }

    public function test_the_candidate_column_links_to_all_candidates_when_more_are_waiting(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        foreach (range(1, 4) as $i) {
            PlaceCandidate::create(['external_place_id' => "osm:n{$i}", 'name' => "Kandidat {$i}", 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'pending']);
        }

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Lihat semua');
    }

    // --- quota ---

    public function test_it_shows_the_geoapify_credits_spent_today_against_the_daily_limit(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        config(['services.geoapify.daily_credits' => 3000]);
        Cache::put('geoapify:credits:'.now()->toDateString(), 42);
        Cache::put('geoapify:credits:'.now()->subDay()->toDateString(), 900);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Kredit Geoapify', '42', 'dari 3.000 hari ini']);
    }

    // --- work columns ---

    public function test_it_lists_places_missing_estimated_cost(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $missing = $this->makePlace(['name' => 'Tanpa Biaya', 'type' => 'lodging', 'kecamatan' => 'Batam Kota', 'estimated_cost_idr' => null]);
        $this->makePlace(['name' => 'Ada Biaya', 'external_place_id' => 'gp-2', 'category_tags_reviewed' => true, 'estimated_cost_idr' => 50000]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Belum ada harga', 'Tanpa Biaya', 'Batam Kota · Hotel', 'Harga kamar', 'Lengkapi']);
        $response->assertSee(route('admin.places.edit', $missing), false);
        $response->assertDontSee('Ada Biaya');
    }

    public function test_it_lists_places_with_unreviewed_category_tags(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $beach = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $unreviewed = $this->makePlace(['name' => 'Belum Direview', 'category_tags_reviewed' => false, 'estimated_cost_idr' => 0]);
        $unreviewed->categories()->attach($beach->categories_id);
        $this->makePlace(['name' => 'Sudah Direview', 'external_place_id' => 'gp-2', 'category_tags_reviewed' => true, 'estimated_cost_idr' => 0]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Tag belum dicek', 'Belum Direview', 'Usulan: Pantai', '1 tag', 'Cek tag']);
        $response->assertDontSee('Sudah Direview');
    }

    // --- summary ---

    public function test_it_shows_the_average_in_app_rating(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $reviewer = User::factory()->create();
        $place = $this->makePlace();
        PlaceReview::create(['places_id' => $place->places_id, 'users_id' => $reviewer->users_id, 'rating' => 4]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Rata-rata rating', '4,0', 'Dari ulasan di aplikasi']);
    }

    public function test_it_shows_the_trip_volume(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $owner = User::factory()->create();
        Trip::create(['users_id' => $owner->users_id, 'title' => 'T1', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);
        Trip::create(['users_id' => $owner->users_id, 'title' => 'T2', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Trip dibuat', '2', 'Total semua pengguna']);
    }
}
