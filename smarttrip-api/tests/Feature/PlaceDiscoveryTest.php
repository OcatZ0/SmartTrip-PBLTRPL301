<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PlaceDiscoveryTest extends TestCase
{
    use RefreshDatabase;

    private function fakeSearchResult(string $googlePlaceId = 'gp-discover-1', string $name = 'Pantai Test'): void
    {
        Http::fake([
            'places.googleapis.com/*' => Http::response([
                'places' => [[
                    'id' => $googlePlaceId,
                    'displayName' => ['text' => $name],
                    'location' => ['latitude' => 1.15, 'longitude' => 104.05],
                    'types' => ['tourist_attraction'],
                ]],
            ]),
        ]);
    }

    public function test_discovery_stores_a_new_candidate_from_the_search_results(): void
    {
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseHas('place_candidates', [
            'google_place_id' => 'gp-discover-1',
            'name' => 'Pantai Test',
            'status' => 'pending',
        ]);
    }

    public function test_the_same_google_place_id_is_only_inserted_once_across_all_area_and_category_combinations(): void
    {
        // Http::fake dengan wildcard membalas request apapun dengan tempat
        // yang sama persis - jadi ini juga sekalian membuktikan re-trigger
        // Discovery (36 kombinasi area x kategori) tidak dobel-insert
        // kandidat yang sama.
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(1, PlaceCandidate::where('google_place_id', 'gp-discover-1')->count());
    }

    public function test_discovery_skips_a_place_id_that_is_already_a_promoted_place(): void
    {
        Place::create([
            'google_place_id' => 'gp-discover-1', 'name' => 'Sudah Jadi Place', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'address' => 'Batam', 'source' => 'manual',
        ]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseMissing('place_candidates', ['google_place_id' => 'gp-discover-1']);
    }

    public function test_discovery_skips_a_place_id_already_rejected_so_it_never_resurfaces(): void
    {
        PlaceCandidate::create([
            'google_place_id' => 'gp-discover-1', 'name' => 'Sudah Ditolak', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'search_area' => 'Nongsa', 'status' => 'rejected',
        ]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(1, PlaceCandidate::where('google_place_id', 'gp-discover-1')->count());
        $this->assertDatabaseHas('place_candidates', ['google_place_id' => 'gp-discover-1', 'status' => 'rejected']);
    }

    public function test_discovery_skips_a_place_id_belonging_to_a_soft_deleted_place(): void
    {
        $place = Place::create([
            'google_place_id' => 'gp-discover-1', 'name' => 'Place Terhapus', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'address' => 'Batam', 'source' => 'manual',
        ]);
        $place->delete();
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseMissing('place_candidates', ['google_place_id' => 'gp-discover-1']);
    }

    public function test_the_console_command_runs_successfully(): void
    {
        $this->fakeSearchResult();

        $this->artisan('places:discover')->assertExitCode(0);

        $this->assertDatabaseHas('place_candidates', ['google_place_id' => 'gp-discover-1']);
    }

    public function test_discovery_records_the_search_area_and_category_type(): void
    {
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $candidate = PlaceCandidate::where('google_place_id', 'gp-discover-1')->first();
        $this->assertContains($candidate->search_area, PlaceDiscoveryService::AREAS);
        $this->assertContains($candidate->type, array_keys(PlaceDiscoveryService::CATEGORY_QUERIES));
    }

    /**
     * Google gagal (misal API key salah/expired) di satu kombinasi tidak
     * boleh menggagalkan seluruh batch 36 kombinasi - errornya dikumpulkan,
     * bukan dilempar mentah-mentah sampai membatalkan sisa proses.
     */
    public function test_a_failure_on_one_combination_does_not_abort_the_whole_batch(): void
    {
        Http::fake([
            'places.googleapis.com/*' => Http::response(['error' => 'boom'], 403),
        ]);

        $result = app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(0, $result['inserted']);
        $this->assertCount(36, $result['failed']);
    }

    public function test_the_console_command_exits_with_a_failure_code_when_google_is_unreachable(): void
    {
        Http::fake([
            'places.googleapis.com/*' => Http::response(['error' => 'boom'], 403),
        ]);

        $this->artisan('places:discover')->assertExitCode(1);
    }
}
