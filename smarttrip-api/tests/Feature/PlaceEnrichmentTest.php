<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Services\Places\PlaceEnrichmentService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class PlaceEnrichmentTest extends TestCase
{
    use RefreshDatabase;

    private Category $pantai;

    private Category $sejarah;

    protected function setUp(): void
    {
        parent::setUp();

        $this->pantai = Category::create(['name_id' => 'Pantai', 'name_en' => 'Beach', 'slug' => 'pantai']);
        $this->sejarah = Category::create(['name_id' => 'Sejarah', 'name_en' => 'History', 'slug' => 'sejarah']);
    }

    private function fakeGemini(array $answer = []): void
    {
        Http::fake([
            'generativelanguage.googleapis.com/*' => Http::response([
                'candidates' => [[
                    'content' => ['parts' => [[
                        'text' => json_encode(array_merge([
                            'description_id' => 'Pantai berpasir putih di Nongsa.',
                            'description_confidence' => 'sedang',
                            'description_en' => 'A white sand beach in Nongsa.',
                            'category_tags' => ['pantai', 'bukan-kategori'],
                            'estimated_visit_minutes' => 90,
                            'is_outdoor' => true,
                            'estimated_cost_idr' => 15000,
                        ], $answer)),
                    ]]],
                ]],
            ]),
        ]);
    }

    private function makePlace(array $overrides = []): Place
    {
        return Place::create(array_merge([
            'name' => 'Pantai Melur', 'type' => 'attraction', 'lat' => 1.05, 'lng' => 104.1,
            'address' => 'Galang', 'kecamatan' => 'Galang', 'source' => 'manual',
        ], $overrides));
    }

    private function enrich(Place $place): array
    {
        return app(PlaceEnrichmentService::class)->enrich($place);
    }

    public function test_a_place_without_a_description_gets_one_written_and_translated_and_is_flagged_for_review(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace(['category_tags_reviewed' => true]);
        $place->update(['category_tags_reviewed' => false]);

        $filled = $this->enrich($place);

        $place->refresh();
        $this->assertSame('Pantai berpasir putih di Nongsa.', $place->description);
        $this->assertSame('A white sand beach in Nongsa.', $place->description_en);
        $this->assertSame(90, $place->estimated_visit_minutes);
        $this->assertTrue($place->is_outdoor);
        // Tags outside the seeded categories are dropped.
        $this->assertSame(['pantai'], $place->categories->pluck('slug')->all());
        $this->assertFalse($place->category_tags_reviewed);
        $this->assertEqualsCanonicalizing(
            ['description', 'description_en', 'estimated_visit_minutes', 'is_outdoor', 'categories', 'estimated_cost_idr'],
            $filled
        );
        Http::assertSent(fn ($request) => str_contains($request['contents'][0]['parts'][0]['text'], 'belum punya deskripsi')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'Pantai Melur, attraction, Galang'));
    }

    public function test_an_existing_description_is_only_translated_and_the_admin_override_wins(): void
    {
        $this->fakeGemini(['description_id' => 'Gemini tidak boleh menimpa ini.']);
        $place = $this->makePlace([
            'description' => 'Deskripsi sumber.',
            'description_override' => 'Deskripsi versi admin.',
        ]);

        $this->enrich($place);

        $place->refresh();
        $this->assertSame('Deskripsi sumber.', $place->description);
        $this->assertSame('Deskripsi versi admin.', $place->description_override);
        $this->assertSame('A white sand beach in Nongsa.', $place->description_en);
        Http::assertSent(fn ($request) => str_contains($request['contents'][0]['parts'][0]['text'], 'Deskripsi versi admin.'));
    }

    public function test_reviewed_tags_duration_and_outdoor_flag_are_kept(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace([
            'estimated_visit_minutes' => 45, 'is_outdoor' => false, 'category_tags_reviewed' => true,
        ]);
        $place->categories()->attach($this->sejarah->categories_id);

        $filled = $this->enrich($place);

        $place->refresh();
        $this->assertSame(['description', 'description_en', 'estimated_cost_idr'], $filled);
        $this->assertSame(45, $place->estimated_visit_minutes);
        $this->assertFalse($place->is_outdoor);
        $this->assertSame(['sejarah'], $place->categories->pluck('slug')->all());
        // The new AI description still needs an admin's eye.
        $this->assertFalse($place->category_tags_reviewed);
    }

    public function test_a_hotel_gets_a_description_but_no_interest_categories_or_visit_length(): void
    {
        $this->fakeGemini(['is_outdoor' => false, 'estimated_cost_idr' => 650000]);
        $place = $this->makePlace(['name' => 'Mercure Batam', 'type' => 'lodging']);

        $filled = $this->enrich($place);

        $place->refresh();
        $this->assertSame(['description', 'description_en', 'is_outdoor', 'estimated_cost_idr'], $filled);
        $this->assertNull($place->estimated_visit_minutes);
        $this->assertSame(0, $place->categories()->count());
    }

    public function test_a_gemini_failure_surfaces_as_a_runtime_exception_and_changes_nothing(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response(['error' => 'quota'], 400)]);
        $place = $this->makePlace();

        try {
            $this->enrich($place);
            $this->fail('Expected a RuntimeException.');
        } catch (RuntimeException) {
            $this->assertNull($place->fresh()->description);
        }
    }

    public function test_a_missing_cost_gets_a_gemini_estimate(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace();

        $this->assertContains('estimated_cost_idr', $this->enrich($place));

        $this->assertSame(15000, $place->fresh()->estimated_cost_idr);
    }

    public function test_an_admin_cost_is_never_replaced_by_the_estimate(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace(['estimated_cost_idr' => 0]);

        $this->assertNotContains('estimated_cost_idr', $this->enrich($place));

        $this->assertSame(0, $place->fresh()->estimated_cost_idr);
    }

    public function test_a_cost_only_estimate_keeps_the_tag_review(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace([
            'description' => 'Ada.', 'description_en' => 'There.', 'estimated_visit_minutes' => 60,
            'is_outdoor' => true, 'category_tags_reviewed' => true,
        ]);
        $place->categories()->attach($this->pantai->categories_id);

        $this->assertSame(['estimated_cost_idr'], $this->enrich($place));
        $this->assertTrue($place->fresh()->category_tags_reviewed);
    }

    public function test_an_unusable_cost_from_gemini_is_ignored(): void
    {
        foreach (['mahal', -5000, 99_000_000] as $answer) {
            $this->fakeGemini(['estimated_cost_idr' => $answer]);
            $place = $this->makePlace();

            $this->enrich($place);

            $this->assertNull($place->fresh()->estimated_cost_idr);
        }
    }

    public function test_the_command_enriches_only_places_with_gaps(): void
    {
        $this->fakeGemini();
        $gap = $this->makePlace(['name' => 'Pantai Kosong']);
        $complete = $this->makePlace([
            'name' => 'Sudah Lengkap', 'description' => 'Ada.', 'description_en' => 'There.',
            'estimated_visit_minutes' => 60, 'is_outdoor' => true, 'category_tags_reviewed' => true,
            'estimated_cost_idr' => 0, 'search_keywords' => 'pasir putih, sunset',
        ]);
        $complete->categories()->attach($this->pantai->categories_id);

        $this->artisan('places:enrich', ['--sleep' => 0])
            ->expectsOutputToContain('Enrichment 1 tempat')
            ->assertExitCode(0);

        $this->assertNotNull($gap->fresh()->description);
        $this->assertSame('Ada.', $complete->fresh()->description);
        Http::assertSentCount(1);
    }

    public function test_an_enriched_hotel_is_not_sent_to_gemini_again(): void
    {
        Http::fake();
        // A hotel after a first enrichment: described, unreviewed, and with no
        // visit length or categories on purpose.
        $this->makePlace([
            'name' => 'Mercure Batam', 'type' => 'lodging', 'description' => 'Hotel.',
            'description_en' => 'Hotel.', 'is_outdoor' => false, 'category_tags_reviewed' => false,
            'estimated_cost_idr' => 650000, 'search_keywords' => 'kolam renang, dekat pelabuhan',
        ]);

        $this->artisan('places:enrich', ['--sleep' => 0])
            ->expectsOutput('Tidak ada tempat yang perlu di-enrich.')
            ->assertExitCode(0);

        Http::assertNothingSent();
    }

    public function test_the_command_reports_failures_with_a_failure_exit_code(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response(['error' => 'quota'], 400)]);
        $this->makePlace();

        $this->artisan('places:enrich', ['--sleep' => 0])
            ->expectsOutputToContain('1 tempat gagal')
            ->assertExitCode(1);
    }

    public function test_the_command_says_so_when_nothing_needs_enrichment(): void
    {
        Http::fake();

        $this->artisan('places:enrich', ['--sleep' => 0])
            ->expectsOutput('Tidak ada tempat yang perlu di-enrich.')
            ->assertExitCode(0);

        Http::assertNothingSent();
    }

    public function test_the_request_carries_the_schema_and_the_source_facts(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace([
            'types' => ['beach', 'natural'], 'opening_hours' => ['mon' => [['08:00', '18:00']], 'sun' => []],
        ]);

        $this->enrich($place);

        Http::assertSent(function ($request) {
            $prompt = $request['contents'][0]['parts'][0]['text'];
            $schema = $request['generationConfig']['responseSchema'];

            return str_contains($prompt, 'Kategori Geoapify/OpenStreetMap: beach, natural')
                && str_contains($prompt, 'Jam buka: Senin: 08.00–18.00; Minggu: Tutup')
                && $schema['properties']['is_outdoor']['type'] === 'BOOLEAN'
                && $schema['properties']['category_tags']['items']['enum'] === ['pantai', 'sejarah']
                && in_array('description_confidence', $schema['required'], true);
        });
    }

    public function test_a_discovery_place_gets_its_osm_tags_as_facts(): void
    {
        Http::fake([
            'api.geoapify.com/*' => Http::response(['features' => [['properties' => [
                'feature_type' => 'details', 'name' => 'Kedai Laut', 'lat' => 1.1, 'lon' => 104.0,
                'datasource' => ['raw' => ['cuisine' => 'seafood', 'outdoor_seating' => 'yes', 'phone' => '+62 811 000']],
            ]]]]),
            'generativelanguage.googleapis.com/*' => Http::response(['candidates' => [['content' => ['parts' => [[
                'text' => json_encode(['description_id' => null, 'description_confidence' => null, 'description_en' => null,
                    'category_tags' => [], 'estimated_visit_minutes' => 60, 'is_outdoor' => null, 'estimated_cost_idr' => null, 'search_keywords' => []]),
            ]]]]]]),
        ]);
        $place = $this->makePlace(['name' => 'Kedai Laut', 'type' => 'culinary', 'external_place_id' => 'osm:n123']);

        $this->enrich($place);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'generativelanguage')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'Tag OpenStreetMap cuisine: seafood')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'Tag OpenStreetMap outdoor_seating: yes')
            && ! str_contains($request['contents'][0]['parts'][0]['text'], '+62 811 000'));
    }

    public function test_a_description_the_ai_is_unsure_about_is_not_kept_nor_its_translation(): void
    {
        $this->fakeGemini(['description_confidence' => 'rendah']);
        $place = $this->makePlace();

        $filled = $this->enrich($place);

        $place->refresh();
        $this->assertNull($place->description);
        $this->assertNull($place->description_en);
        $this->assertNotContains('description', $filled);
    }

    public function test_a_written_description_with_a_price_phone_or_made_up_hours_is_dropped(): void
    {
        foreach ([
            'Tiket masuk Rp 10.000 per orang.',
            'Hubungi 0812 3456 789 untuk reservasi.',
            'Buka setiap hari pukul 08.00 sampai sore.',
        ] as $text) {
            $this->fakeGemini(['description_id' => $text, 'description_confidence' => 'tinggi']);
            $place = $this->makePlace();

            $this->enrich($place);

            $this->assertNull($place->fresh()->description, $text);
        }
    }

    public function test_hours_in_the_description_are_fine_when_the_source_has_opening_hours(): void
    {
        $this->fakeGemini(['description_id' => 'Buka sejak 08.00 setiap hari.', 'description_confidence' => 'tinggi']);
        $place = $this->makePlace(['opening_hours' => ['mon' => [['08:00', '17:00']]]]);

        $this->enrich($place);

        $this->assertSame('Buka sejak 08.00 setiap hari.', $place->fresh()->description);
    }

    public function test_an_unreasonable_visit_length_or_cost_for_the_type_is_dropped(): void
    {
        $this->fakeGemini(['estimated_visit_minutes' => 600, 'estimated_cost_idr' => 1000]);
        $place = $this->makePlace(['name' => 'Warung Mak Uteh', 'type' => 'culinary']);

        $this->enrich($place);

        $place->refresh();
        $this->assertNull($place->estimated_visit_minutes);
        $this->assertNull($place->estimated_cost_idr);
    }

    public function test_the_osm_category_settles_indoor_or_outdoor(): void
    {
        $this->fakeGemini(['is_outdoor' => false]);
        $beach = $this->makePlace(['types' => ['beach']]);
        $this->enrich($beach);
        $this->assertTrue($beach->fresh()->is_outdoor);

        $this->fakeGemini(['is_outdoor' => true]);
        $mall = $this->makePlace(['name' => 'Grand Batam Mall', 'types' => ['commercial.shopping_mall']]);
        $this->enrich($mall);
        $this->assertFalse($mall->fresh()->is_outdoor);
    }

    public function test_wrong_types_from_gemini_are_dropped_not_cast(): void
    {
        $this->fakeGemini([
            'is_outdoor' => 'false',
            'estimated_visit_minutes' => '1,5 jam',
            'description_en' => ['not', 'text'],
            'category_tags' => 'pantai',
        ]);
        $place = $this->makePlace();

        $this->enrich($place);

        $place->refresh();
        // "false" as text is read as false, never as PHP's truthy string.
        $this->assertFalse($place->is_outdoor);
        $this->assertNull($place->estimated_visit_minutes);
        $this->assertNull($place->description_en);
        $this->assertSame(0, $place->categories()->count());
    }

    public function test_the_dry_run_shows_the_plan_and_saves_nothing(): void
    {
        $this->fakeGemini();
        $place = $this->makePlace();

        $this->artisan('places:enrich', ['--sleep' => 0, '--dry-run' => true])
            ->expectsOutputToContain('Fakta untuk AI:')
            ->expectsOutputToContain('Dry run: tidak ada yang disimpan.')
            ->assertExitCode(0);

        $this->assertNull($place->fresh()->description);
        $this->assertSame(0, $place->categories()->count());
    }

    private function fakeGeminiAndGoogle(int $searchesLeft): void
    {
        config(['services.serpapi.api_key' => 'serp-key', 'services.serpapi.reserve' => 50]);
        Http::fake(function (\Illuminate\Http\Client\Request $request) use ($searchesLeft) {
            $url = $request->url();
            if (str_contains($url, 'serpapi.com/account')) {
                return Http::response(['total_searches_left' => $searchesLeft]);
            }
            if (str_contains($url, 'serpapi.com/search')) {
                return Http::response($request['engine'] === 'google_maps'
                    ? ['place_results' => [
                        'title' => 'Pantai Melur', 'gps_coordinates' => ['latitude' => 1.0501, 'longitude' => 104.1001],
                        'type' => ['Pantai'], 'open_state' => 'Buka', 'hours' => [['senin' => '08.00–18.00'], ['minggu' => '07.00–19.00']],
                    ]]
                    : ['organic_results' => [['title' => 'Tiket Pantai Melur', 'link' => 'https://wisata.example/melur', 'snippet' => 'Tiket masuk Rp 10.000.', 'date' => '1 Jan 2026']]]);
            }

            return Http::response(['candidates' => [['content' => ['parts' => [['text' => json_encode([
                'description_id' => 'Pantai berpasir di Galang.', 'description_confidence' => 'sedang',
                'description_en' => 'A sandy beach in Galang.', 'category_tags' => ['pantai'],
                'estimated_visit_minutes' => 90, 'is_outdoor' => true, 'estimated_cost_idr' => 10000, 'search_keywords' => ['pasir'],
            ])]]]]]]);
        });
    }

    public function test_enrichment_reads_google_maps_and_the_web_and_copies_the_hours(): void
    {
        $this->fakeGeminiAndGoogle(200);
        $place = $this->makePlace();

        $filled = $this->enrich($place);

        $this->assertContains('opening_hours', $filled);
        $this->assertSame(['mon' => [['08:00', '18:00']], 'sun' => [['07:00', '19:00']]], $place->fresh()->opening_hours);
        Http::assertSent(fn ($request) => str_contains($request->url(), 'generativelanguage')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'Jam buka di Google Maps: Senin: 08.00–18.00')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'Tiket masuk Rp 10.000.'));
    }

    public function test_enrichment_keeps_the_last_searches_for_the_admin(): void
    {
        $this->fakeGeminiAndGoogle(50);
        $place = $this->makePlace();

        $this->enrich($place);

        $this->assertNull($place->fresh()->opening_hours);
        Http::assertNotSent(fn ($request) => str_contains($request->url(), 'serpapi.com/search'));
    }

    public function test_existing_hours_are_not_replaced(): void
    {
        $this->fakeGeminiAndGoogle(200);
        $place = $this->makePlace(['opening_hours' => ['mon' => [['06:00', '18:00']]]]);

        $this->assertNotContains('opening_hours', $this->enrich($place));
        $this->assertSame(['mon' => [['06:00', '18:00']]], $place->fresh()->opening_hours);
    }
}
