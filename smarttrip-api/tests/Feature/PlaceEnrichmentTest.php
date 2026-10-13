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
                            'description_en' => 'A white sand beach in Nongsa.',
                            'category_tags' => ['pantai', 'bukan-kategori'],
                            'estimated_visit_minutes' => 90,
                            'is_outdoor' => true,
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
            ['description', 'description_en', 'estimated_visit_minutes', 'is_outdoor', 'categories'],
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
        $this->assertSame(['description', 'description_en'], $filled);
        $this->assertSame(45, $place->estimated_visit_minutes);
        $this->assertFalse($place->is_outdoor);
        $this->assertSame(['sejarah'], $place->categories->pluck('slug')->all());
        // The new AI description still needs an admin's eye.
        $this->assertFalse($place->category_tags_reviewed);
    }

    public function test_a_hotel_gets_a_description_but_no_interest_categories_or_visit_length(): void
    {
        $this->fakeGemini(['is_outdoor' => false]);
        $place = $this->makePlace(['name' => 'Mercure Batam', 'type' => 'lodging']);

        $filled = $this->enrich($place);

        $place->refresh();
        $this->assertSame(['description', 'description_en', 'is_outdoor'], $filled);
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

    public function test_the_command_enriches_only_places_with_gaps(): void
    {
        $this->fakeGemini();
        $gap = $this->makePlace(['name' => 'Pantai Kosong']);
        $complete = $this->makePlace([
            'name' => 'Sudah Lengkap', 'description' => 'Ada.', 'description_en' => 'There.',
            'estimated_visit_minutes' => 60, 'is_outdoor' => true, 'category_tags_reviewed' => true,
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
}
