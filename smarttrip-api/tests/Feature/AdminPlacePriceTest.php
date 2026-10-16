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

        config(['services.gemini.api_key' => 'test-key', 'services.gemini.model' => 'gemini-test']);
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->place = Place::create([
            'name' => 'Amaris Hotel Nagoya Hill Batam', 'type' => 'lodging', 'lat' => 1.1446, 'lng' => 104.0128,
            'address' => 'Nagoya, Lubuk Baja, Batam', 'kecamatan' => 'Lubuk Baja', 'source' => 'manual',
        ]);
    }

    private function geminiAnswer(array $answer): array
    {
        return ['candidates' => [['content' => ['parts' => [['text' => json_encode($answer)]]]]]];
    }

    public function test_the_price_estimate_returns_gemini_explanation_and_number(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response($this->geminiAnswer([
            'estimated_cost_idr' => 520000,
            'explanation' => 'Kisaran Rp 450.000 - Rp 600.000 per malam untuk kamar standar.',
        ]))]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.price-estimate', $this->place))
            ->assertOk()
            ->assertExactJson([
                'text' => 'Kisaran Rp 450.000 - Rp 600.000 per malam untuk kamar standar.',
                'estimated_cost_idr' => 520000,
            ]);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'models/gemini-test:generateContent')
            && ! isset($request['tools'])
            && str_contains($request['contents'][0]['parts'][0]['text'], 'harga kamar standar per malam'));
    }

    public function test_an_unusable_estimate_number_is_dropped(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response($this->geminiAnswer([
            'estimated_cost_idr' => 'mahal', 'explanation' => 'Tidak yakin.',
        ]))]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.price-estimate', $this->place))
            ->assertOk()
            ->assertJsonPath('estimated_cost_idr', null)
            ->assertJsonPath('text', 'Tidak yakin.');
    }

    public function test_the_price_estimate_never_stores_anything(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response($this->geminiAnswer([
            'estimated_cost_idr' => 520000, 'explanation' => 'x',
        ]))]);

        $this->actingAs($this->admin)->getJson(route('admin.places.price-estimate', $this->place))->assertOk();

        $this->assertNull($this->place->fresh()->estimated_cost_idr);
    }

    public function test_a_retired_gemini_model_is_named_in_the_error(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response(['error' => ['code' => 404]], 404)]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.price-estimate', $this->place))
            ->assertStatus(502)
            ->assertJsonPath('message', 'Model Gemini "gemini-test" tidak tersedia. Periksa GEMINI_MODEL di .env.');
    }

    public function test_a_used_up_gemini_quota_is_reported(): void
    {
        Http::fake(['generativelanguage.googleapis.com/*' => Http::response(['error' => ['code' => 429]], 429)]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.price-estimate', $this->place))
            ->assertStatus(502)
            ->assertJsonPath('message', 'Kuota Gemini sedang habis, coba lagi beberapa saat lagi.');
    }

    public function test_the_price_estimate_is_admin_only(): void
    {
        Http::fake();
        $user = User::factory()->create(['role' => 'user']);

        $this->actingAs($user)->getJson(route('admin.places.price-estimate', $this->place))->assertForbidden();

        Http::assertNothingSent();
    }

    public function test_the_edit_page_offers_the_price_estimate(): void
    {
        $this->place->update(['estimated_cost_idr' => 500000]);

        $this->actingAs($this->admin)
            ->get(route('admin.places.edit', $this->place))
            ->assertOk()
            ->assertDontSee('Perkiraan AI')
            ->assertSee('Perkirakan harga dengan AI');
    }

    public function test_an_admin_can_change_the_cost(): void
    {
        $this->place->update(['estimated_cost_idr' => 500000]);

        $this->actingAs($this->admin)
            ->put(route('admin.places.update', $this->place), ['estimated_cost_idr' => 550000])
            ->assertRedirect();

        $this->assertSame(550000, $this->place->fresh()->estimated_cost_idr);
    }
}
