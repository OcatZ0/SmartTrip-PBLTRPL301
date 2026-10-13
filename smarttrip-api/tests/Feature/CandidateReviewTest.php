<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\User;
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
            'google_place_id' => 'gp-review-1', 'name' => 'Pantai Kandidat', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'search_area' => 'Nongsa', 'status' => 'pending',
        ], $overrides));
    }

    private function fakeDetailsPhotoAndGemini(): void
    {
        Http::fake([
            'places.googleapis.com/v1/places/*/media' => Http::response('fake-image-bytes'),
            'places.googleapis.com/v1/places/*' => Http::response([
                'id' => 'gp-review-1',
                'displayName' => ['text' => 'Pantai Kandidat Lengkap'],
                'formattedAddress' => 'Nongsa, Batam',
                'location' => ['latitude' => 1.15, 'longitude' => 104.05],
                'types' => ['tourist_attraction'],
                'rating' => 4.5,
                'userRatingCount' => 120,
                'priceLevel' => 'PRICE_LEVEL_MODERATE',
                'editorialSummary' => ['text' => 'Pantai yang indah.'],
                'businessStatus' => 'OPERATIONAL',
                'photos' => [['name' => 'places/gp-review-1/photos/abc']],
            ]),
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

    public function test_the_list_defaults_to_pending_candidates(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $this->makeCandidate(['name' => 'Pending A']);
        $this->makeCandidate(['name' => 'Rejected B', 'google_place_id' => 'gp-2', 'status' => 'rejected']);

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
        $this->makeCandidate(['name' => 'Sekupang Punya', 'google_place_id' => 'gp-2', 'search_area' => 'Sekupang']);

        $response = $this->actingAs($admin)->get('/admin/candidates?search_area=Sekupang');

        $response->assertOk();
        $response->assertSee('Sekupang Punya');
        $response->assertDontSee('Nongsa Punya');
    }

    // --- approve ---

    public function test_approving_a_candidate_promotes_it_to_a_full_place_with_photo_and_gemini_tags(): void
    {
        Storage::fake('public');
        $category = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        $this->fakeDetailsPhotoAndGemini();

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('approved', $candidate->fresh()->status);

        $place = Place::where('google_place_id', 'gp-review-1')->first();
        $this->assertNotNull($place);
        $this->assertSame('Pantai Kandidat Lengkap', $place->name);
        $this->assertSame('Nongsa', $place->kecamatan);
        $this->assertSame('A beautiful beach.', $place->description_en);
        $this->assertSame(90, $place->estimated_visit_minutes);
        $this->assertTrue((bool) $place->is_outdoor);
        $this->assertNotNull($place->photo_url);
        $this->assertTrue($place->categories->contains('categories_id', $category->categories_id));
        $this->assertCount(1, $place->photos);
    }

    public function test_approving_never_attaches_a_gemini_suggested_tag_outside_the_known_category_list(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        // "pantai" category sengaja TIDAK di-seed - Gemini menyarankannya tapi harus dibuang.
        $this->fakeDetailsPhotoAndGemini();

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $place = Place::where('google_place_id', 'gp-review-1')->first();
        $this->assertCount(0, $place->categories);
    }

    public function test_a_place_details_failure_leaves_the_candidate_pending_and_creates_no_place(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake(['places.googleapis.com/*' => Http::response(['error' => 'boom'], 403)]);

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('pending', $candidate->fresh()->status);
        $this->assertDatabaseMissing('places', ['google_place_id' => 'gp-review-1']);
    }

    public function test_a_gemini_failure_still_leaves_the_place_promoted_with_core_fields(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake([
            'places.googleapis.com/v1/places/*/media' => Http::response('fake-image-bytes'),
            'places.googleapis.com/v1/places/*' => Http::response([
                'id' => 'gp-review-1', 'displayName' => ['text' => 'Pantai Kandidat Lengkap'],
                'formattedAddress' => 'Nongsa, Batam', 'location' => ['latitude' => 1.15, 'longitude' => 104.05],
                'businessStatus' => 'OPERATIONAL',
            ]),
            'generativelanguage.googleapis.com/*' => Http::response(['error' => 'boom'], 500),
        ]);

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('approved', $candidate->fresh()->status);
        $place = Place::where('google_place_id', 'gp-review-1')->first();
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
            'places.googleapis.com/v1/places/*/media' => Http::response('fake-image-bytes'),
            'places.googleapis.com/v1/places/*' => Http::response([
                'id' => 'gp-review-1', 'displayName' => ['text' => 'Pantai Kandidat Lengkap'],
                'formattedAddress' => 'Nongsa, Batam', 'location' => ['latitude' => 1.15, 'longitude' => 104.05],
                'businessStatus' => 'OPERATIONAL',
            ]),
            'generativelanguage.googleapis.com/*' => fn () => throw new ConnectionException('cURL error 28: Operation timed out'),
        ]);

        $response = $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $response->assertRedirect();
        $this->assertSame('approved', $candidate->fresh()->status);
        $this->assertNotNull(Place::where('google_place_id', 'gp-review-1')->first());
    }

    public function test_gemini_is_retried_after_a_temporary_high_demand_error(): void
    {
        Storage::fake('public');
        Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $admin = User::factory()->create(['role' => 'admin']);
        $candidate = $this->makeCandidate();
        Http::fake([
            'places.googleapis.com/v1/places/*/media' => Http::response('fake-image-bytes'),
            'places.googleapis.com/v1/places/*' => Http::response([
                'id' => 'gp-review-1', 'displayName' => ['text' => 'Pantai Kandidat Lengkap'],
                'formattedAddress' => 'Nongsa, Batam', 'location' => ['latitude' => 1.15, 'longitude' => 104.05],
                'businessStatus' => 'OPERATIONAL',
            ]),
            'generativelanguage.googleapis.com/*' => Http::sequence()
                ->push(['error' => ['code' => 503, 'status' => 'UNAVAILABLE']], 503)
                ->push(['candidates' => [['content' => ['parts' => [['text' => json_encode([
                    'description_en' => 'A beautiful beach.', 'category_tags' => ['pantai'],
                    'estimated_visit_minutes' => 90, 'is_outdoor' => true,
                ])]]]]]]),
        ]);

        $this->actingAs($admin)->post("/admin/candidates/{$candidate->place_candidates_id}/approve");

        $place = Place::where('google_place_id', 'gp-review-1')->first();
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
        $this->assertDatabaseMissing('places', ['google_place_id' => 'gp-review-1']);
    }

    // --- bulk actions ---

    public function test_candidates_can_be_bulk_rejected(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $a = $this->makeCandidate(['name' => 'A']);
        $b = $this->makeCandidate(['name' => 'B', 'google_place_id' => 'gp-2']);

        $response = $this->actingAs($admin)->post('/admin/candidates/bulk-reject', [
            'ids' => [$a->place_candidates_id, $b->place_candidates_id],
        ]);

        $response->assertRedirect();
        $this->assertSame('rejected', $a->fresh()->status);
        $this->assertSame('rejected', $b->fresh()->status);
    }

    public function test_candidates_can_be_bulk_approved(): void
    {
        Storage::fake('public');
        $admin = User::factory()->create(['role' => 'admin']);
        $a = $this->makeCandidate(['name' => 'A', 'google_place_id' => 'gp-review-1']);
        $b = $this->makeCandidate(['name' => 'B', 'google_place_id' => 'gp-review-2']);
        Http::fake([
            'places.googleapis.com/v1/places/*/media' => Http::response('fake-image-bytes'),
            'places.googleapis.com/v1/places/*' => Http::response([
                'displayName' => ['text' => 'Promoted'], 'formattedAddress' => 'Batam',
                'location' => ['latitude' => 1.15, 'longitude' => 104.05], 'businessStatus' => 'OPERATIONAL',
            ]),
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [['content' => ['parts' => [['text' => '{}']]]]],
            ]),
        ]);

        $response = $this->actingAs($admin)->post('/admin/candidates/bulk-approve', [
            'ids' => [$a->place_candidates_id, $b->place_candidates_id],
        ]);

        $response->assertRedirect();
        $this->assertSame('approved', $a->fresh()->status);
        $this->assertSame('approved', $b->fresh()->status);
        $this->assertSame(2, Place::count());
    }

    // --- discovery trigger ---

    public function test_the_discovery_button_triggers_discovery_and_redirects_with_a_summary(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Http::fake([
            'places.googleapis.com/*' => Http::response([
                'places' => [['id' => 'gp-triggered', 'displayName' => ['text' => 'Baru'], 'location' => ['latitude' => 1.1, 'longitude' => 104.1], 'types' => []]],
            ]),
        ]);

        $response = $this->actingAs($admin)->post('/admin/candidates/discover');

        $response->assertRedirect(route('admin.candidates.index'));
        $this->assertDatabaseHas('place_candidates', ['google_place_id' => 'gp-triggered']);
    }
}
