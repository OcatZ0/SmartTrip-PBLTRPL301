<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\User;
use App\Services\Places\GooglePlaceLookupClient;
use App\Services\Places\OpeningHours;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AdminPlaceDataEstimateTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private Place $place;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.serpapi.api_key' => 'serp-key', 'services.gemini.api_key' => 'test-key', 'services.gemini.model' => 'gemini-test']);
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->place = Place::create([
            'name' => 'Acia Ikan Bakar', 'type' => 'culinary', 'lat' => 1.1421, 'lng' => 104.0111,
            'address' => 'Jalan Pembangunan, Lubuk Baja', 'kecamatan' => 'Lubuk Baja', 'source' => 'geoapify',
        ]);
    }

    private function mapsResult(array $overrides = []): array
    {
        return ['place_results' => array_merge([
            'title' => 'Acia Ikan Bakar',
            'place_id' => 'ChIJabc',
            'gps_coordinates' => ['latitude' => 1.14216, 'longitude' => 104.01109],
            'type' => ['Restoran Ikan Bakar', 'Restoran Seafood'],
            'address' => 'Lubuk Baja Kota, Kec. Lubuk Baja, Kota Batam',
            'open_state' => 'Buka · Tutup pukul 23.00',
            'hours' => [['sabtu' => '11.00–23.00'], ['minggu' => '11.00–23.00'], ['senin' => '11.00–23.00']],
            'rating' => 4.4,
            'reviews' => 1597,
        ], $overrides)];
    }

    private function webResult(): array
    {
        return ['organic_results' => [
            ['title' => 'Menu Acia Ikan Bakar Batam', 'link' => 'https://kuliner.example/acia', 'source' => 'Kuliner Batam', 'date' => '3 Mar 2026',
                'snippet' => 'Ikan bakar mulai Rp 60.000, rata-rata Rp 80.000 per orang.'],
            ['title' => 'Video tanpa snippet', 'link' => 'https://video.example/1'],
        ]];
    }

    private function geminiAnswer(array $answer): array
    {
        return ['candidates' => [['content' => ['parts' => [['text' => json_encode($answer)]]]]]];
    }

    private function fakeAll(array $maps, array $web, array $answer): void
    {
        Http::fake(function (Request $request) use ($maps, $web, $answer) {
            if (str_contains($request->url(), 'serpapi.com/search')) {
                return Http::response($request['engine'] === 'google_maps' ? $maps : $web);
            }
            if (str_contains($request->url(), 'generativelanguage.googleapis.com')) {
                return Http::response($this->geminiAnswer($answer));
            }

            return Http::response([], 404);
        });
    }

    private function answer(array $overrides = []): array
    {
        return array_merge([
            'estimated_cost_idr' => ['value' => 80000, 'sources' => [2], 'note' => 'Rata-rata per orang menurut sumber 2026.'],
            'estimated_visit_minutes' => ['value' => 60, 'sources' => [1], 'note' => 'Restoran, sekali makan.'],
            'is_outdoor' => ['value' => false, 'sources' => [1], 'note' => 'Restoran.'],
        ], $overrides);
    }

    public function test_the_estimate_returns_each_value_with_its_sources_and_the_maps_hours(): void
    {
        $this->fakeAll($this->mapsResult(), $this->webResult(), $this->answer());

        $response = $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))->assertOk();

        $response->assertJsonPath('fields.estimated_cost_idr.value', 80000)
            ->assertJsonPath('fields.estimated_cost_idr.sources', [2])
            ->assertJsonPath('fields.estimated_visit_minutes.value', 60)
            ->assertJsonPath('fields.is_outdoor.value', false)
            // Copied from Google Maps, Monday first, not written by Gemini.
            ->assertJsonPath('fields.opening_hours.value', ['Senin: 11.00–23.00', 'Sabtu: 11.00–23.00', 'Minggu: 11.00–23.00'])
            // Only three days known: the rows fill those and leave the rest unfilled.
            ->assertJsonPath('fields.opening_hours.rows.mon', ['state' => 'open', 'open' => '11:00', 'close' => '23:00'])
            ->assertJsonPath('fields.opening_hours.rows.tue', ['state' => '', 'open' => '', 'close' => ''])
            ->assertJsonPath('sources.0.number', 1)
            ->assertJsonPath('sources.0.source', 'Google Maps')
            ->assertJsonPath('sources.1.link', 'https://kuliner.example/acia')
            ->assertJsonCount(2, 'sources')
            ->assertJsonPath('closed', null);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'generativelanguage')
            && str_contains($request['contents'][0]['parts'][0]['text'], '[2] Menu Acia Ikan Bakar Batam (Kuliner Batam, 3 Mar 2026)')
            && str_contains($request['contents'][0]['parts'][0]['text'], 'Jam buka: Senin: 11.00–23.00'));
    }

    public function test_a_value_without_a_real_source_or_outside_the_range_is_dropped(): void
    {
        $this->fakeAll($this->mapsResult(), $this->webResult(), $this->answer([
            'estimated_cost_idr' => ['value' => 80000, 'sources' => [9], 'note' => 'Kira-kira.'],
            'estimated_visit_minutes' => ['value' => 600, 'sources' => [1], 'note' => 'Lama.'],
            'is_outdoor' => ['value' => true, 'sources' => [], 'note' => 'Tebakan.'],
        ]));

        $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))
            ->assertOk()
            ->assertJsonPath('fields.estimated_cost_idr.value', null)
            ->assertJsonPath('fields.estimated_cost_idr.note', 'Tidak ada sumber yang menyebutkannya.')
            ->assertJsonPath('fields.estimated_visit_minutes.value', null)
            ->assertJsonPath('fields.is_outdoor.value', null);
    }

    public function test_a_maps_result_far_from_the_place_is_another_place(): void
    {
        $this->fakeAll($this->mapsResult(['gps_coordinates' => ['latitude' => 1.30, 'longitude' => 104.20]]), ['organic_results' => []], $this->answer());

        $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))
            ->assertOk()
            ->assertJsonPath('fields.opening_hours.value', null)
            ->assertJsonCount(0, 'sources');

        // Nothing to read, so Gemini is not asked.
        Http::assertNotSent(fn ($request) => str_contains($request->url(), 'generativelanguage'));
    }

    public function test_a_permanently_closed_place_is_flagged_without_asking_gemini(): void
    {
        $this->fakeAll($this->mapsResult(['open_state' => 'Permanently closed', 'hours' => null]), $this->webResult(), $this->answer());

        $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))
            ->assertOk()
            ->assertJsonPath('closed', 'permanent')
            ->assertJsonPath('fields.estimated_cost_idr.value', null)
            ->assertJsonPath('sources.0.source', 'Google Maps');
        Http::assertNotSent(fn ($request) => str_contains($request->url(), 'generativelanguage'));
    }

    public function test_the_edit_page_offers_to_delete_a_permanently_closed_place(): void
    {
        $this->actingAs($this->admin)->get(route('admin.places.edit', $this->place))
            ->assertOk()
            ->assertSee('Hapus dari katalog')
            ->assertDontSee('Tandai tutup permanen')
            ->assertDontSee('business_status');
    }

    public function test_the_lookup_is_cached_so_a_second_click_spends_no_search(): void
    {
        $this->fakeAll($this->mapsResult(), $this->webResult(), $this->answer());

        $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))->assertOk();
        $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))->assertOk();

        Http::assertSentCount(4); // 2 SerpApi searches once, Gemini twice
    }

    public function test_an_empty_quota_is_reported(): void
    {
        Http::fake(['serpapi.com/*' => Http::response(['error' => 'run out'], 429)]);

        $this->actingAs($this->admin)->getJson(route('admin.places.data-estimate', $this->place))
            ->assertStatus(502)
            ->assertJsonPath('message', 'Kuota pencarian SerpApi bulan ini sudah habis.');
    }

    public function test_the_edit_page_has_one_data_button_and_the_seven_day_rows(): void
    {
        $this->place->update(['opening_hours' => OpeningHours::fromOsm('Mo-Fr 09:00-17:00; Sa 09:00-12:00')]);

        $this->actingAs($this->admin)->get(route('admin.places.edit', $this->place))
            ->assertOk()
            ->assertSee('Perkiraan data dengan AI')
            ->assertDontSee('Perkirakan harga dengan AI')
            ->assertSeeInOrder(['Senin', 'name="opening_hours[mon][open]" value="09:00"', 'Sabtu', 'value="12:00"', 'Minggu'], false);
    }

    public function test_saving_the_seven_day_rows(): void
    {
        $this->actingAs($this->admin)->put(route('admin.places.update', $this->place), [
            'opening_hours_changed' => '1',
            'opening_hours' => ['mon' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'], 'tue' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'],
                'wed' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'], 'thu' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'],
                'fri' => ['state' => 'open', 'open' => '09:00', 'close' => '19:00'], 'sat' => ['state' => 'closed'], 'sun' => ['state' => '24h']],
        ])->assertRedirect()->assertSessionHasNoErrors();

        $this->place->refresh();
        $this->assertSame([['09:00', '19:00']], $this->place->opening_hours['mon']);
        $this->assertSame([], $this->place->opening_hours['sat']);
        $this->assertSame([['00:00', '24:00']], $this->place->opening_hours['sun']);
        $this->assertArrayNotHasKey('weekday_descriptions', $this->place->opening_hours);
    }

    public function test_an_open_day_needs_both_times(): void
    {
        $this->actingAs($this->admin)
            ->from(route('admin.places.edit', $this->place))
            ->put(route('admin.places.update', $this->place), [
                'opening_hours_changed' => '1',
                'opening_hours' => ['mon' => ['state' => 'open', 'open' => '09:00']],
            ])
            ->assertSessionHasErrors('opening_hours.mon.close');
    }

    public function test_untouched_rows_keep_the_stored_hours(): void
    {
        $this->place->update(['opening_hours' => ['mon' => [['12:00', '24:00']]]]);

        $this->actingAs($this->admin)->put(route('admin.places.update', $this->place), [
            'opening_hours_changed' => '0',
            'opening_hours' => ['mon' => ['state' => 'closed']],
        ])->assertRedirect();

        $this->assertSame(['mon' => [['12:00', '24:00']]], $this->place->fresh()->opening_hours);
    }

    public function test_clearing_every_row_removes_the_hours(): void
    {
        $this->place->update(['opening_hours' => ['mon' => [['12:00', '24:00']]]]);

        $this->actingAs($this->admin)->put(route('admin.places.update', $this->place), [
            'opening_hours_changed' => '1',
            'opening_hours' => ['mon' => ['state' => '']],
        ])->assertRedirect();

        $this->assertNull($this->place->fresh()->opening_hours);
    }

    public function test_the_data_estimate_is_admin_only(): void
    {
        Http::fake();
        $user = User::factory()->create(['role' => 'user']);

        $this->actingAs($user)->getJson(route('admin.places.data-estimate', $this->place))->assertForbidden();

        Http::assertNothingSent();
    }

    public function test_an_admin_can_change_the_cost(): void
    {
        $this->place->update(['estimated_cost_idr' => 500000]);

        $this->actingAs($this->admin)
            ->put(route('admin.places.update', $this->place), ['estimated_cost_idr' => 550000])
            ->assertRedirect();

        $this->assertSame(550000, $this->place->fresh()->estimated_cost_idr);
    }

    public function test_hours_lines_accept_english_day_names(): void
    {
        $this->assertSame(
            ['Senin: 9 AM–6 PM', 'Minggu: Closed'],
            GooglePlaceLookupClient::hoursLines(['sunday' => 'Closed', 'monday' => '9 AM–6 PM'])
        );
    }
}
