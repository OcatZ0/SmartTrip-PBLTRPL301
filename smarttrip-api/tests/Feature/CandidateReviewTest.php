<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\User;
use App\Services\Places\PlaceCandidateReviewService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class CandidateReviewTest extends TestCase
{
    use RefreshDatabase;

    private function makeCandidate(array $overrides = []): PlaceCandidate
    {
        return PlaceCandidate::create(array_merge([
            'external_place_id' => 'osm:n2001', 'name' => 'Pantai Kandidat', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'search_area' => 'Nongsa', 'status' => 'pending',
        ], $overrides));
    }

    private function fakeDetailsAndGemini(): void
    {
        Http::fake([
            'api.geoapify.com/v2/place-details*' => Http::response(['features' => [[
                'properties' => [
                    'feature_type' => 'details',
                    'place_id' => 'osm:n2001',
                    'name' => 'Pantai Kandidat Lengkap',
                    'formatted' => 'Nongsa, Batam',
                    'lat' => 1.15,
                    'lon' => 104.05,
                    'categories' => ['beach'],
                    'opening_hours' => 'Mo-Su 08:00-18:00',
                    'website' => 'https://pantai.example',
                    'contact' => ['phone' => '+62 778 123'],
                ],
            ]]]),
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => ['parts' => [[
                        'text' => json_encode([
                            'description_en' => 'A beautiful beach.',
                            'category_tags' => ['pantai'],
                            'estimated_visit_minutes' => 90,
                            'is_outdoor' => true,
                        ]),
                    ]]],
                ]],
            ]),
        ]);
    }

    // --- access control ---

    public function test_a_guest_is_redirected_to_login(): void
    {
        $response = $this->get('/admin/candidates');

        $response->assertRedirect('/admin/login');
    }

    public function test_a_non_admin_user_is_forbidden(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->get('/admin/candidates');

        $response->assertForbidden();
    }

    // --- list/filter ---

    public function test_the_list_speaks_indonesian_and_counts_each_status(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Kuliner A', 'type' => 'culinary', 'external_place_id' => 'osm:n1']);
        $this->makeCandidate(['name' => 'Pending B', 'external_place_id' => 'osm:n2']);
        $this->makeCandidate(['name' => 'Ditolak C', 'status' => 'rejected', 'external_place_id' => 'osm:n3']);

        $response = $this->actingAs($admin)->get('/admin/candidates');

        $response->assertOk();
        $response->assertSeeInOrder(['Menunggu review', '2', 'Disetujui', '0', 'Ditolak', '1']);
        $response->assertSee('Kuliner');
        $response->assertSee('Setujui terpilih');
        $response->assertDontSee('Approve Terpilih');
        $response->assertDontSee('>Reject<', false);
        $response->assertDontSee('>culinary<', false);
    }

    public function test_the_list_can_be_searched_by_name_or_osm_id(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Pantai Melur', 'external_place_id' => 'osm:n111']);
        $this->makeCandidate(['name' => 'Kedai Kopi', 'external_place_id' => 'osm:w222']);

        $byName = $this->actingAs($admin)->get('/admin/candidates?search=melur');
        $byName->assertSee('Pantai Melur');
        $byName->assertDontSee('Kedai Kopi');

        $byId = $this->actingAs($admin)->get('/admin/candidates?search=w222');
        $byId->assertSee('Kedai Kopi');
        $byId->assertDontSee('Pantai Melur');
    }

    public function test_the_list_can_be_filtered_by_type_and_the_tabs_follow_it(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Hotel Satu', 'type' => 'lodging', 'external_place_id' => 'osm:n1']);
        $this->makeCandidate(['name' => 'Hotel Dua', 'type' => 'lodging', 'status' => 'rejected', 'external_place_id' => 'osm:n2']);
        $this->makeCandidate(['name' => 'Pantai Tiga', 'external_place_id' => 'osm:n3']);

        $response = $this->actingAs($admin)->get('/admin/candidates?type=lodging');

        $response->assertSee('Hotel Satu');
        $response->assertDontSee('Pantai Tiga');
        $response->assertSeeInOrder(['Menunggu review', '1', 'Disetujui', '0', 'Ditolak', '1']);
    }

    public function test_the_list_uses_the_admin_pagination(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        foreach (range(1, 26) as $number) {
            $this->makeCandidate(['name' => "Kandidat {$number}", 'external_place_id' => "osm:n{$number}"]);
        }

        $response = $this->actingAs($admin)->get('/admin/candidates');

        $response->assertSee('Menampilkan 1–25 dari 26 kandidat');
        $response->assertSee('aria-label="Halaman berikutnya"', false);
        $response->assertDontSee('Showing');
    }

    public function test_the_list_defaults_to_pending_candidates(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Pending A']);
        $this->makeCandidate(['name' => 'Rejected B', 'external_place_id' => 'osm:n2003', 'status' => 'rejected']);

        $response = $this->actingAs($admin)->get('/admin/candidates');

        $response->assertOk();
        $response->assertSee('Pending A');
        $response->assertDontSee('Rejected B');
    }

    public function test_the_list_can_be_filtered_by_status(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Rejected B', 'status' => 'rejected']);

        $response = $this->actingAs($admin)->get('/admin/candidates?status=rejected');

        $response->assertOk();
        $response->assertSee('Rejected B');
    }

    public function test_the_list_can_be_filtered_by_search_area(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Nongsa Punya', 'search_area' => 'Nongsa']);
        $this->makeCandidate(['name' => 'Sekupang Punya', 'external_place_id' => 'osm:n2003', 'search_area' => 'Sekupang']);

        $response = $this->actingAs($admin)->get('/admin/candidates?search_area=Sekupang');

        $response->assertOk();
        $response->assertSee('Sekupang Punya');
        $response->assertDontSee('Nongsa Punya');
    }

    // --- approve ---

    public function test_approving_a_candidate_promotes_it_to_a_full_place_with_gemini_tags(): void
    {
        Storage::fake('public');
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        $this->fakeDetailsAndGemini();

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('approved', $candidate->fresh()->status);

        $place = Place::where('external_place_id', 'osm:n2001')->first();
        $this->assertNotNull($place);
        $this->assertSame('Pantai Kandidat Lengkap', $place->name);
        $this->assertSame('Nongsa', $place->kecamatan);
        $this->assertSame('A beautiful beach.', $place->description_en);
        $this->assertSame(90, $place->estimated_visit_minutes);
        $this->assertTrue((bool) $place->is_outdoor);
        $this->assertSame('geoapify', $place->source);
        $this->assertSame('+62 778 123', $place->phone);
        $this->assertSame(['osm' => 'Mo-Su 08:00-18:00'], $place->opening_hours);
        // Geoapify has no ratings or photos; the admin adds photos.
        $this->assertNull($place->rating);
        $this->assertNull($place->photo_url);
        $this->assertTrue($place->categories->contains('categories_id', $category->categories_id));
    }

    public function test_approving_never_attaches_a_gemini_suggested_tag_outside_the_known_category_list(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        // "pantai" category sengaja TIDAK di-seed - Gemini menyarankannya tapi harus dibuang.
        $this->fakeDetailsAndGemini();

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $place = Place::where('external_place_id', 'osm:n2001')->first();
        $this->assertCount(0, $place->categories);
    }

    public function test_a_place_details_failure_leaves_the_candidate_pending_and_creates_no_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake(['api.geoapify.com/*' => Http::response(['error' => 'boom'], 403)]);

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('pending', $candidate->fresh()->status);
        $this->assertDatabaseMissing('places', ['external_place_id' => 'osm:n2001']);
    }

    public function test_a_gemini_failure_still_leaves_the_place_promoted_with_core_fields(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake([
            'api.geoapify.com/v2/place-details*' => Http::response(['features' => [[
                'properties' => [
                    'feature_type' => 'details',
                    'place_id' => 'osm:n2001',
                    'name' => 'Pantai Kandidat Lengkap',
                    'formatted' => 'Nongsa, Batam',
                    'lat' => 1.15,
                    'lon' => 104.05,
                    'categories' => ['beach'],
                ],
            ]]]),
            'generativelanguage.googleapis.com/*' => Http::response(['error' => 'boom'], 500),
        ]);

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('approved', $candidate->fresh()->status);
        $place = Place::where('external_place_id', 'osm:n2001')->first();
        $this->assertNotNull($place);
        $this->assertNull($place->description_en);
        $this->assertFalse((bool) $place->category_tags_reviewed);
    }

    public function test_a_gemini_timeout_still_leaves_the_place_promoted_instead_of_a_server_error(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake([
            'api.geoapify.com/v2/place-details*' => Http::response(['features' => [[
                'properties' => [
                    'feature_type' => 'details',
                    'place_id' => 'osm:n2001',
                    'name' => 'Pantai Kandidat Lengkap',
                    'formatted' => 'Nongsa, Batam',
                    'lat' => 1.15,
                    'lon' => 104.05,
                    'categories' => ['beach'],
                ],
            ]]]),
            'generativelanguage.googleapis.com/*' => fn () => throw new ConnectionException('cURL error 28: Operation timed out'),
        ]);

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('approved', $candidate->fresh()->status);
        $this->assertNotNull(Place::where('external_place_id', 'osm:n2001')->first());
    }

    public function test_gemini_is_retried_after_a_temporary_high_demand_error(): void
    {
        Storage::fake('public');
        Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake([
            'api.geoapify.com/v2/place-details*' => Http::response(['features' => [[
                'properties' => [
                    'feature_type' => 'details',
                    'place_id' => 'osm:n2001',
                    'name' => 'Pantai Kandidat Lengkap',
                    'formatted' => 'Nongsa, Batam',
                    'lat' => 1.15,
                    'lon' => 104.05,
                    'categories' => ['beach'],
                ],
            ]]]),
            'generativelanguage.googleapis.com/*' => Http::sequence()
                ->push(['error' => ['code' => 503, 'status' => 'UNAVAILABLE']], 503)
                ->push(['candidates' => [['content' => ['parts' => [['text' => json_encode([
                    'description_en' => 'A beautiful beach.', 'category_tags' => ['pantai'],
                    'estimated_visit_minutes' => 90, 'is_outdoor' => true,
                ])]]]]]]),
        ]);

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $place = Place::where('external_place_id', 'osm:n2001')->first();
        $this->assertSame('A beautiful beach.', $place->description_en);
        $this->assertSame(90, $place->estimated_visit_minutes);
    }

    public function test_a_non_admin_cannot_approve_a_candidate(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $candidate = $this->makeCandidate();

        $response = $this->actingAs($user)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertForbidden();
        $this->assertSame('pending', $candidate->fresh()->status);
    }

    // --- reject ---

    public function test_rejecting_a_candidate_marks_it_rejected_without_creating_a_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/reject");

        $response->assertRedirect();
        $this->assertSame('rejected', $candidate->fresh()->status);
        $this->assertDatabaseMissing('places', ['external_place_id' => 'osm:n2001']);
    }

    // --- status transitions ---

    public function test_a_rejected_candidate_can_still_be_approved(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate(['status' => 'rejected']);
        $this->fakeDetailsAndGemini();

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve")->assertRedirect();

        $this->assertSame('approved', $candidate->fresh()->status);
        $this->assertDatabaseHas('places', ['external_place_id' => 'osm:n2001']);
    }

    public function test_an_approved_candidate_cannot_be_approved_again(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate(['status' => 'approved']);
        Http::fake();

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve")
            ->assertRedirect()
            ->assertSessionHas('error', 'Gagal menyetujui "Pantai Kandidat": kandidat ini sudah disetujui');

        Http::assertNothingSent();
        $this->assertDatabaseMissing('places', ['external_place_id' => 'osm:n2001']);
    }

    public function test_an_approved_candidate_cannot_be_rejected(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate(['status' => 'approved']);

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/reject")
            ->assertRedirect()
            ->assertSessionHas('error', 'Gagal menolak "Pantai Kandidat": hanya kandidat yang menunggu review yang bisa ditolak');

        $this->assertSame('approved', $candidate->fresh()->status);
    }

    public function test_bulk_reject_skips_candidates_that_are_not_pending(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $pending = $this->makeCandidate(['name' => 'Masih Pending']);
        $approved = $this->makeCandidate(['name' => 'Sudah Disetujui', 'external_place_id' => 'osm:n2003', 'status' => 'approved']);

        $this->actingAs($admin)->post('/admin/candidates/bulk-reject', ['ids' => [$pending->place_candidates_id, $approved->place_candidates_id]])
            ->assertRedirect()
            ->assertSessionHas('status', '1 kandidat ditolak, 1 dilewati karena statusnya bukan menunggu.');

        $this->assertSame('rejected', $pending->fresh()->status);
        $this->assertSame('approved', $approved->fresh()->status);
    }

    public function test_the_list_only_shows_the_actions_allowed_for_each_status(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $rejected = $this->makeCandidate(['name' => 'Ditolak', 'status' => 'rejected']);
        $approved = $this->makeCandidate(['name' => 'Disetujui', 'external_place_id' => 'osm:n2003', 'status' => 'approved']);

        $rejectedPage = $this->actingAs($admin)->get('/admin/candidates?status=rejected');
        $rejectedPage->assertSee(route('admin.candidates.approve', $rejected), false);
        $rejectedPage->assertDontSee(route('admin.candidates.reject', $rejected), false);

        $approvedPage = $this->actingAs($admin)->get('/admin/candidates?status=approved');
        $approvedPage->assertDontSee(route('admin.candidates.approve', $approved), false);
        $approvedPage->assertDontSee(route('admin.candidates.reject', $approved), false);
        $approvedPage->assertSee('Sudah di katalog');
    }

    // --- bulk actions ---

    public function test_candidates_can_be_bulk_rejected(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $firstCandidate = $this->makeCandidate(['name' => 'A']);
        $secondCandidate = $this->makeCandidate(['name' => 'B', 'external_place_id' => 'osm:n2003']);

        $response = $this->actingAs($admin)->post('/admin/candidates/bulk-reject', [
            'ids' => [$firstCandidate->place_candidates_id, $secondCandidate->place_candidates_id],
        ]);

        $response->assertRedirect();
        $this->assertSame('rejected', $firstCandidate->fresh()->status);
        $this->assertSame('rejected', $secondCandidate->fresh()->status);
    }

    public function test_candidates_can_be_bulk_approved(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $firstCandidate = $this->makeCandidate(['name' => 'A', 'external_place_id' => 'osm:n2001']);
        $secondCandidate = $this->makeCandidate(['name' => 'B', 'external_place_id' => 'osm:n2002']);
        Http::fake([
            'api.geoapify.com/v2/place-details*' => Http::response(['features' => [[
                'properties' => [
                    'feature_type' => 'details',
                    'place_id' => 'osm:n2001',
                    'name' => 'Promoted',
                    'formatted' => 'Nongsa, Batam',
                    'lat' => 1.15,
                    'lon' => 104.05,
                    'categories' => ['beach'],
                ],
            ]]]),
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [['content' => ['parts' => [['text' => '{}']]]]],
            ]),
        ]);

        $response = $this->actingAs($admin)->post('/admin/candidates/bulk-approve', [
            'ids' => [$firstCandidate->place_candidates_id, $secondCandidate->place_candidates_id],
        ]);

        $response->assertRedirect();
        $this->assertSame('approved', $firstCandidate->fresh()->status);
        $this->assertSame('approved', $secondCandidate->fresh()->status);
        $this->assertSame(2, Place::count());
    }

    // --- discovery trigger ---

    public function test_the_discovery_button_triggers_discovery_and_redirects_with_a_summary(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Http::fake([
            'api.geoapify.com/v2/places*' => Http::response(['features' => [[
                'properties' => [
                    'place_id' => 'geoapify-opaque', 'name' => 'Baru', 'lat' => 1.1, 'lon' => 104.1, 'categories' => [],
                    'datasource' => ['raw' => ['osm_type' => 'n', 'osm_id' => 3001]],
                ],
            ]]]),
        ]);

        $response = $this->actingAs($admin)->post('/admin/candidates/discover');

        $response->assertRedirect(route('admin.candidates.index'));
        $this->assertDatabaseHas('place_candidates', ['external_place_id' => 'osm:n3001']);
    }

    // --- duplicates ---

    public function test_approve_looks_up_details_by_the_openstreetmap_element(): void
    {
        config(['services.geoapify.api_key' => 'geo-test-key']);
        $candidate = $this->makeCandidate(['external_place_id' => 'osm:w2001']);
        $this->fakeDetailsAndGemini();

        app(PlaceCandidateReviewService::class)->approve($candidate);

        Http::assertSent(fn ($request) => str_starts_with($request->url(), 'https://api.geoapify.com/v2/place-details')
            && $request['osm_type'] === 'w'
            && $request['osm_id'] === '2001');
    }

    public function test_approve_refuses_a_candidate_whose_place_is_already_in_the_catalog(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        // Added by hand after Discovery, so no external id; ~45 m away.
        Place::create([
            'name' => 'Pantai Kandidat Nongsa', 'type' => 'attraction', 'lat' => 1.1504, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'manual',
        ]);
        $candidate = $this->makeCandidate();
        Http::fake();

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertSessionHas('error', fn (string $message) => str_contains($message, 'Pantai Kandidat Nongsa'));
        $this->assertSame('pending', $candidate->fresh()->status);
        $this->assertSame(1, Place::count());
        Http::assertNothingSent();
    }

    public function test_the_reject_duplicates_command_rejects_pending_copies_and_keeps_the_first(): void
    {
        Place::create([
            'external_place_id' => 'osm:n5000', 'name' => 'Masjid Agung Batam', 'type' => 'attraction',
            'lat' => 1.1264, 'lng' => 104.0534, 'address' => 'Batam', 'source' => 'manual',
        ]);
        $sameElement = $this->makeCandidate(['external_place_id' => 'osm:n5000', 'name' => 'Masjid Agung', 'lat' => 1.2, 'lng' => 104.2]);
        $nearbySameName = $this->makeCandidate(['external_place_id' => 'osm:w5001', 'name' => 'Masjid Agung Batam', 'lat' => 1.1265, 'lng' => 104.0535]);
        $first = $this->makeCandidate(['external_place_id' => 'osm:n6000', 'name' => 'Pantai Ocarina']);
        $copy = $this->makeCandidate(['external_place_id' => 'osm:w6001', 'name' => 'Ocarina', 'lat' => 1.1502]);
        $unrelated = $this->makeCandidate(['external_place_id' => 'osm:n7000', 'name' => 'Kedai Kopi', 'lat' => 1.1501]);

        $this->artisan('places:reject-duplicates')
            ->expectsOutput('3 kandidat duplikat ditolak.')
            ->assertExitCode(0);

        $this->assertSame('rejected', $sameElement->fresh()->status);
        $this->assertSame('rejected', $nearbySameName->fresh()->status);
        $this->assertSame('pending', $first->fresh()->status);
        $this->assertSame('rejected', $copy->fresh()->status);
        $this->assertSame('pending', $unrelated->fresh()->status);
    }
}
