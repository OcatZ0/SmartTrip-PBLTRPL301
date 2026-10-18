<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlaceReview;
use App\Models\Trip;
use App\Models\TripWishlistPlace;
use App\Models\User;
use App\Services\ApiUsage;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
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
        $response->assertSee('Belum ada tempat yang disetujui');
        $response->assertSee('Tidak ada yang perlu dikerjakan.');
        $response->assertSee('Belum ada tempat yang masuk wishlist.');
    }

    public function test_every_admin_page_shares_the_nav_rail_with_the_skppl_menu_names(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        foreach (['/admin/dashboard', '/admin/candidates', '/admin/places', '/admin/categories'] as $url) {
            $response = $this->actingAs($admin)->get($url);

            $response->assertOk();
            $response->assertSee('aria-label="Navigasi admin"', false);
            $response->assertSee('class="admin-rail-toggle" aria-controls="admin-rail"', false);
            $response->assertSee('<header class="admin-topbar">', false);
            $response->assertSee('class="admin-topbar-scene"', false);
            $response->assertSeeInOrder(['Dashboard', 'Kandidat Tempat', 'Kelola Tempat', 'Kelola Kategori']);
            $response->assertDontSee('SmartTrip Batam');
        }
    }

    public function test_nested_admin_pages_show_their_title_and_a_back_link_in_the_topbar(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['name' => 'Pantai & Bukit']);

        $response = $this->actingAs($admin)->get(route('admin.places.edit', $place));

        $response->assertOk();
        $response->assertSeeInOrder(['admin-topbar-back', 'Kelola Tempat', 'admin-topbar-title', 'Pantai &amp; Bukit'], false);
        $response->assertDontSee('&amp;amp;', false);
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
        // Stored in UTC, shown in WIB: 08.00 UTC is 15.00 WIB.
        $response->assertSee('Discovery terakhir '.$candidate->fresh()->created_at->timezone('Asia/Jakarta')->translatedFormat('j M Y, H.i').' WIB');
        $response->assertSee('15.00 WIB');
    }

    public function test_it_shows_the_last_approval_timestamp_from_the_newest_provider_sourced_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $place = $this->makePlace(['source' => 'google', 'external_place_id' => 'gp-1']);
        $place->forceFill(['created_at' => '2026-06-15 10:00:00'])->save();
        // Manual place tidak dihitung sebagai tempat yang disetujui dari kandidat.
        $manual = $this->makePlace(['source' => 'manual', 'external_place_id' => null]);
        $manual->forceFill(['created_at' => '2026-08-01 10:00:00'])->save();

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSee('Tempat terakhir disetujui '.$place->fresh()->created_at->timezone('Asia/Jakarta')->translatedFormat('j M Y, H.i').' WIB');
        $response->assertDontSee($manual->fresh()->created_at->timezone('Asia/Jakarta')->translatedFormat('j M Y, H.i'));
    }

    public function test_the_candidate_column_links_to_all_candidates_when_more_are_waiting(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        foreach (range(1, 4) as $number) {
            PlaceCandidate::create(['external_place_id' => "osm:n{$number}", 'name' => "Kandidat {$number}", 'type' => 'attraction', 'lat' => 1.1, 'lng' => 104.1, 'search_area' => 'Nongsa', 'status' => 'pending']);
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
        $response->assertSeeInOrder(['Kuota API', 'Geoapify', '42', '/ 3.000 kredit hari ini']);
    }

    public function test_the_api_quota_card_shows_every_provider(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        config([
            'services.gemini.daily_limit' => 500, 'services.openrouteservice.daily_limit' => 2000,
            'services.serpapi.api_key' => 'serp-key',
        ]);
        Http::fake(['serpapi.com/account*' => Http::response([
            'searches_per_month' => 250, 'total_searches_left' => 190, 'this_month_usage' => 60, 'plan_renewal_date' => '2026-11-15',
        ])]);
        ApiUsage::record(ApiUsage::GEMINI, 125);
        ApiUsage::record(ApiUsage::OPENROUTESERVICE, 7);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk()
            ->assertSeeInOrder(['Gemini', '25%', '125', '/ 500 hari ini'])
            ->assertSeeInOrder(['SerpApi', '24%', '60', '/ 250 bulan ini', 'Reset 15 Nov 2026'])
            ->assertSeeInOrder(['OpenRouteService', '7', '/ 2.000 hari ini']);
    }

    public function test_an_unreadable_serpapi_account_does_not_break_the_dashboard(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $this->actingAs($admin)->get('/admin/dashboard')
            ->assertOk()
            ->assertSee('Tidak terbaca, periksa SERPAPI_API_KEY');
    }

    // --- work columns ---

    public function test_one_card_counts_every_kind_of_missing_data(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace([
            'name' => 'Tanpa Biaya', 'estimated_cost_idr' => null, 'category_tags_reviewed' => true,
            'estimated_visit_minutes' => 60, 'description_en' => 'There.', 'search_keywords' => 'pantai',
            'photo_url' => 'https://example.com/a.jpg', 'opening_hours' => array_fill_keys(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], [['00:00', '24:00']]),
        ]);
        $this->makePlace([
            'name' => 'Hotel Lengkap', 'type' => 'lodging', 'external_place_id' => 'gp-2', 'estimated_cost_idr' => 400000,
            'category_tags_reviewed' => true, 'estimated_visit_minutes' => null, 'description_en' => 'Hotel.',
            'search_keywords' => 'hotel', 'photo_url' => 'https://example.com/b.jpg', 'opening_hours' => array_fill_keys(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], [['00:00', '24:00']]),
        ]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk()
            ->assertDontSee('Tag belum dicek</h2>', false)
            ->assertSeeInOrder(['Data belum lengkap', '1</b> dari 2 tempat masih kurang data'], false)
            ->assertSeeInOrder(['Belum ada harga', 'Kriteria anggaran di itinerary', '1', 'Lengkapi'])
            // A hotel needs no visit length, so that row is complete.
            ->assertSeeInOrder(['Belum ada lama kunjungan', 'Menentukan muat tidaknya satu hari', 'Lengkap'])
            ->assertSee(route('admin.places.index', ['kurang' => 'harga']), false);
    }

    public function test_the_places_list_filters_by_missing_data(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Tanpa Biaya', 'estimated_cost_idr' => null]);
        $this->makePlace(['name' => 'Ada Biaya', 'external_place_id' => 'gp-2', 'estimated_cost_idr' => 50000]);

        $this->actingAs($admin)->get(route('admin.places.index', ['kurang' => 'harga']))
            ->assertOk()
            ->assertSee('Tanpa Biaya')
            ->assertDontSee('Ada Biaya')
            ->assertSee('name="kurang[]" value="harga" checked', false);

        // An unknown gap is ignored.
        $this->actingAs($admin)->get(route('admin.places.index', ['kurang' => 'bukan']))
            ->assertOk()
            ->assertSee('Ada Biaya');
    }

    public function test_places_that_need_completing_are_yellow_and_say_what_is_missing(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace([
            'name' => 'Lengkap Semua', 'estimated_cost_idr' => 0, 'category_tags_reviewed' => true,
            'estimated_visit_minutes' => 60, 'description_en' => 'There.', 'search_keywords' => 'pantai',
            'photo_url' => 'https://example.com/a.jpg', 'opening_hours' => array_fill_keys(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], [['00:00', '24:00']]),
        ]);
        $this->makePlace([
            'name' => 'Kurang Dua', 'external_place_id' => 'gp-2', 'estimated_cost_idr' => null, 'category_tags_reviewed' => true,
            'estimated_visit_minutes' => 60, 'description_en' => 'There.', 'search_keywords' => 'pantai',
            'photo_url' => 'https://example.com/b.jpg', 'opening_hours' => null,
        ]);

        $response = $this->actingAs($admin)->get(route('admin.places.index'));

        $response->assertOk()
            ->assertSeeInOrder(['Kurang Dua', 'Kurang: harga, jam buka'])
            ->assertSeeInOrder(['Lengkap Semua', 'Siap tampil'])
            ->assertSee('Siap Tampil di App: 1')
            ->assertSee('Butuh Lengkapi: 1 Tempat');
        $this->assertSame(1, substr_count($response->getContent(), '<tr class="is-incomplete">'));

        $this->actingAs($admin)->get(route('admin.places.index', ['status_data' => 'siap_tampil']))
            ->assertSee('Lengkap Semua')->assertDontSee('Kurang Dua');
        $this->actingAs($admin)->get(route('admin.places.index', ['status_data' => 'butuh_lengkapi']))
            ->assertSee('Kurang Dua')->assertDontSee('Lengkap Semua');
    }

    public function test_ticking_several_gaps_shows_places_missing_any_of_them(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makePlace(['name' => 'Tanpa Biaya', 'estimated_cost_idr' => null, 'opening_hours' => array_fill_keys(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], [['00:00', '24:00']])]);
        $this->makePlace(['name' => 'Tanpa Jam', 'external_place_id' => 'gp-2', 'estimated_cost_idr' => 0, 'opening_hours' => null]);
        $this->makePlace(['name' => 'Ada Keduanya', 'external_place_id' => 'gp-3', 'estimated_cost_idr' => 0, 'opening_hours' => array_fill_keys(['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'], [['00:00', '24:00']])]);

        $this->actingAs($admin)->get(route('admin.places.index', ['kurang' => ['harga', 'jam']]))
            ->assertOk()
            ->assertSee('Tanpa Biaya')
            ->assertSee('Tanpa Jam')
            ->assertDontSee('Ada Keduanya')
            ->assertSee('name="kurang[]" value="harga" checked', false)
            ->assertSee('name="kurang[]" value="jam" checked', false);
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

    public function test_it_lists_the_most_wishlisted_places_in_order(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $owner = User::factory()->create();
        $trip = Trip::create(['users_id' => $owner->users_id, 'title' => 'T', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);
        $anotherTrip = Trip::create(['users_id' => $owner->users_id, 'title' => 'T2', 'num_days' => 1, 'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString()]);
        $popular = $this->makePlace(['name' => 'Populer', 'estimated_cost_idr' => 0, 'category_tags_reviewed' => true]);
        $lessPopular = $this->makePlace(['name' => 'Kurang Populer', 'external_place_id' => 'gp-2', 'estimated_cost_idr' => 0, 'category_tags_reviewed' => true]);
        $this->makePlace(['name' => 'Tidak Pernah Diwishlist', 'external_place_id' => 'gp-3', 'estimated_cost_idr' => 0, 'category_tags_reviewed' => true]);
        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $popular->places_id]);
        TripWishlistPlace::create(['trips_id' => $anotherTrip->trips_id, 'places_id' => $popular->places_id]);
        TripWishlistPlace::create(['trips_id' => $trip->trips_id, 'places_id' => $lessPopular->places_id]);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
        $response->assertSeeInOrder(['Paling banyak di-wishlist', 'Populer', '2 wishlist', 'Kurang Populer', '1 wishlist']);
        $response->assertDontSee('Tidak Pernah Diwishlist');
    }
}
