<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Services\Places\GeoapifyPlacesClient;
use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class PlaceDiscoveryTest extends TestCase
{
    use RefreshDatabase;

    private function feature(string $osmType, int $osmId, string $name, float $lat = 1.15, float $lng = 104.05): array
    {
        return [
            'properties' => [
                'place_id' => 'geoapify-opaque-'.$osmId,
                'name' => $name,
                'lat' => $lat,
                'lon' => $lng,
                'categories' => ['beach'],
                'datasource' => ['sourcename' => 'openstreetmap', 'raw' => ['osm_type' => $osmType, 'osm_id' => $osmId]],
            ],
        ];
    }

    private function fakeSearchResult(string $name = 'Pantai Test', float $lat = 1.15, float $lng = 104.05): void
    {
        Http::fake([
            'api.geoapify.com/v2/places*' => Http::response(['features' => [$this->feature('n', 1001, $name, $lat, $lng)]]),
        ]);
    }

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Test', 'type' => 'attraction', 'lat' => 1.15, 'lng' => 104.05,
            'address' => 'Batam', 'source' => 'manual',
        ], $overrides));
    }

    public function test_discovery_stores_a_new_candidate_from_the_search_results(): void
    {
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseHas('place_candidates', [
            'external_place_id' => 'osm:n1001',
            'name' => 'Pantai Test',
            'status' => 'pending',
        ]);
    }

    public function test_the_same_external_place_id_is_only_inserted_once_across_all_area_and_category_combinations(): void
    {
        // Http::fake dengan wildcard membalas request apapun dengan tempat
        // yang sama persis - jadi ini juga sekalian membuktikan re-trigger
        // Discovery (36 kombinasi area x kategori) tidak dobel-insert
        // kandidat yang sama.
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(1, PlaceCandidate::where('external_place_id', 'osm:n1001')->count());
    }

    public function test_discovery_skips_a_place_id_that_is_already_a_promoted_place(): void
    {
        Place::create([
            'external_place_id' => 'osm:n1001', 'name' => 'Sudah Jadi Place', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'address' => 'Batam', 'source' => 'manual',
        ]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseMissing('place_candidates', ['external_place_id' => 'osm:n1001']);
    }

    public function test_discovery_skips_a_place_id_already_rejected_so_it_never_resurfaces(): void
    {
        PlaceCandidate::create([
            'external_place_id' => 'osm:n1001', 'name' => 'Sudah Ditolak', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'search_area' => 'Nongsa', 'status' => 'rejected',
        ]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(1, PlaceCandidate::where('external_place_id', 'osm:n1001')->count());
        $this->assertDatabaseHas('place_candidates', ['external_place_id' => 'osm:n1001', 'status' => 'rejected']);
    }

    public function test_discovery_skips_a_place_id_belonging_to_a_soft_deleted_place(): void
    {
        $place = Place::create([
            'external_place_id' => 'osm:n1001', 'name' => 'Place Terhapus', 'type' => 'attraction',
            'lat' => 1.15, 'lng' => 104.05, 'address' => 'Batam', 'source' => 'manual',
        ]);
        $place->delete();
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseMissing('place_candidates', ['external_place_id' => 'osm:n1001']);
    }

    public function test_the_console_command_runs_successfully(): void
    {
        $this->fakeSearchResult();

        $this->artisan('places:discover')->assertExitCode(0);

        $this->assertDatabaseHas('place_candidates', ['external_place_id' => 'osm:n1001']);
    }

    public function test_discovery_records_the_search_area_and_category_type(): void
    {
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $candidate = PlaceCandidate::where('external_place_id', 'osm:n1001')->first();
        $this->assertContains($candidate->search_area, array_keys(PlaceDiscoveryService::AREAS));
        $this->assertContains($candidate->type, array_keys(PlaceDiscoveryService::CATEGORY_QUERIES));
    }

    /**
     * Geoapify gagal (misal API key salah/expired) di satu kombinasi tidak
     * boleh menggagalkan seluruh batch 36 kombinasi - errornya dikumpulkan,
     * bukan dilempar mentah-mentah sampai membatalkan sisa proses.
     */
    public function test_a_failure_on_one_combination_does_not_abort_the_whole_batch(): void
    {
        Http::fake([
            'api.geoapify.com/*' => Http::response(['error' => 'boom'], 403),
        ]);

        $result = app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(0, $result['inserted']);
        $this->assertCount(36, $result['failed']);
    }

    public function test_the_console_command_exits_with_a_failure_code_when_geoapify_is_unreachable(): void
    {
        Http::fake([
            'api.geoapify.com/*' => Http::response(['error' => 'boom'], 403),
        ]);

        $this->artisan('places:discover')->assertExitCode(1);
    }

    public function test_discovery_searches_a_circle_around_each_kecamatan_with_lon_lat_order(): void
    {
        config(['services.geoapify.api_key' => 'geo-test-key']);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $nongsa = PlaceDiscoveryService::AREAS['Nongsa'];
        Http::assertSent(fn ($request) => str_starts_with($request->url(), 'https://api.geoapify.com/v2/places')
            && $request['filter'] === "circle:{$nongsa['lng']},{$nongsa['lat']},{$nongsa['radius']}"
            && $request['categories'] === PlaceDiscoveryService::CATEGORY_QUERIES['culinary']
            && $request['conditions'] === 'named'
            && $request['apiKey'] === 'geo-test-key');
    }

    public function test_discovery_records_the_credits_it_spends_for_the_dashboard(): void
    {
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        // 36 searches with at most 20 results each cost 1 credit apiece.
        $this->assertSame(36, GeoapifyPlacesClient::creditsUsedToday());
    }

    public function test_discovery_keys_candidates_by_their_openstreetmap_element_not_the_geoapify_place_id(): void
    {
        Http::fake([
            'api.geoapify.com/v2/places*' => Http::response(['features' => [
                $this->feature('w', 2002, 'Mall Test', 1.20, 104.10),
                // Not from OpenStreetMap: no stable key, left out.
                ['properties' => ['place_id' => 'other-source', 'name' => 'Lain', 'lat' => 1.3, 'lon' => 104.2]],
            ]]),
        ]);

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(['osm:w2002'], PlaceCandidate::pluck('external_place_id')->all());
    }

    public function test_discovery_skips_a_place_without_an_id_that_has_the_same_name_within_100_meters(): void
    {
        // Seeded or hand-entered place, no external id. ~55 m away.
        $this->makePlace(['name' => 'Pantai Ocarina', 'lat' => 1.1505]);
        $this->fakeSearchResult('Ocarina');

        $result = app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(0, $result['inserted']);
        $this->assertSame(0, PlaceCandidate::count());
    }

    public function test_discovery_skips_a_second_osm_element_for_a_candidate_it_already_has(): void
    {
        PlaceCandidate::create([
            'external_place_id' => 'osm:w9999', 'name' => 'Mall Pantai Test', 'type' => 'attraction',
            'lat' => 1.1503, 'lng' => 104.0503, 'search_area' => 'Nongsa', 'status' => 'rejected',
        ]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertSame(1, PlaceCandidate::count());
    }

    public function test_discovery_keeps_a_same_named_branch_more_than_100_meters_away(): void
    {
        // ~330 m away: another branch of the same chain, a different place.
        $this->makePlace(['name' => 'Pantai Test', 'lat' => 1.153]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseHas('place_candidates', ['external_place_id' => 'osm:n1001']);
    }

    public function test_discovery_keeps_a_differently_named_neighbour_within_100_meters(): void
    {
        $this->makePlace(['name' => 'Kedai Kopi Sebelah', 'lat' => 1.1502]);
        $this->fakeSearchResult();

        app(PlaceDiscoveryService::class)->discoverAll();

        $this->assertDatabaseHas('place_candidates', ['external_place_id' => 'osm:n1001']);
    }
}
