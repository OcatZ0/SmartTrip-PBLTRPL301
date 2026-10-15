<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AdminPlacePriceTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private Place $place;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.gemini.api_key' => 'test-key', 'services.gemini.grounding_model' => 'gemini-2.5-flash-lite']);
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->place = Place::create([
            'name' => 'Amaris Hotel Nagoya Hill Batam', 'type' => 'lodging', 'lat' => 1.1446, 'lng' => 104.0128,
            'address' => 'Nagoya, Lubuk Baja, Batam', 'kecamatan' => 'Lubuk Baja', 'source' => 'manual',
        ]);
    }

    private function groundedAnswer(): array
    {
        return ['candidates' => [[
            'content' => ['parts' => [['text' => 'Kisaran Rp 450.000 - Rp 600.000 per malam.'], ['text' => ' Sumber: Traveloka.']]],
            'groundingMetadata' => [
                'searchEntryPoint' => ['renderedContent' => '<style>.chip{}</style><div class="chip">amaris batam harga</div>'],
                'groundingChunks' => [
                    ['web' => ['uri' => 'https://vertexaisearch.cloud.google.com/grounding-api-redirect/abc', 'title' => 'traveloka.com']],
                    ['retrievedContext' => ['uri' => 'gs://internal']],
                ],
            ],
        ]]];
    }

    public function test_the_price_search_returns_gemini_answer_suggestions_and_sources(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response($this->groundedAnswer())]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.price-search', $this->place))
            ->assertOk()
            ->assertJsonPath('text', 'Kisaran Rp 450.000 - Rp 600.000 per malam. Sumber: Traveloka.')
            ->assertJsonPath('search_suggestions', '<style>.chip{}</style><div class="chip">amaris batam harga</div>')
            ->assertJsonPath('sources', [['title' => 'traveloka.com', 'url' => 'https://vertexaisearch.cloud.google.com/grounding-api-redirect/abc']]);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'models/gemini-2.5-flash-lite:generateContent')
            && isset($request['tools'][0]['google_search'])
            && str_contains($request['contents'][0]['parts'][0]['text'], 'harga kamar standar per malam'));
    }

    public function test_the_price_search_never_stores_anything(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response($this->groundedAnswer())]);

        $this->actingAs($this->admin)->getJson(route('admin.places.price-search', $this->place))->assertOk();

        $place = $this->place->fresh();
        $this->assertNull($place->estimated_cost_idr);
        $this->assertFalse($place->estimated_cost_is_ai);
    }

    public function test_a_used_up_gemini_quota_is_reported(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response(['error' => ['code' => 429]], 429)]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.price-search', $this->place))
            ->assertStatus(502)
            ->assertJsonPath('message', 'Kuota pencarian Gemini hari ini sudah habis, coba lagi besok.');
    }

    public function test_the_price_search_is_admin_only(): void
    {
        Http::fake();
        $user = User::factory()->create(['role' => 'user']);

        $this->actingAs($user)->getJson(route('admin.places.price-search', $this->place))->assertForbidden();

        Http::assertNothingSent();
    }

    public function test_the_edit_page_marks_an_ai_cost_and_offers_the_price_search(): void
    {
        $this->place->update(['estimated_cost_idr' => 500000, 'estimated_cost_is_ai' => true]);

        $this->actingAs($this->admin)
            ->get(route('admin.places.edit', $this->place))
            ->assertOk()
            ->assertSee('Perkiraan AI')
            ->assertSee('Cari harga di Google');
    }

    public function test_changing_an_ai_cost_makes_it_the_admin_cost(): void
    {
        $this->place->update(['estimated_cost_idr' => 500000, 'estimated_cost_is_ai' => true]);

        $this->actingAs($this->admin)
            ->put(route('admin.places.update', $this->place), ['estimated_cost_idr' => 550000])
            ->assertRedirect();

        $place = $this->place->fresh();
        $this->assertSame(550000, $place->estimated_cost_idr);
        $this->assertFalse($place->estimated_cost_is_ai);
    }

    public function test_saving_without_changing_an_ai_cost_keeps_the_mark(): void
    {
        $this->place->update(['estimated_cost_idr' => 500000, 'estimated_cost_is_ai' => true]);

        $this->actingAs($this->admin)
            ->put(route('admin.places.update', $this->place), ['estimated_cost_idr' => 500000, 'kecamatan' => 'Lubuk Baja'])
            ->assertRedirect();

        $this->assertTrue($this->place->fresh()->estimated_cost_is_ai);
    }
}
