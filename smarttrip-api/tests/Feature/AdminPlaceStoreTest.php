<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Place;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AdminPlaceStoreTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.geoapify.api_key' => 'test-key']);
        $this->admin = User::factory()->create(['role' => 'admin']);
    }

    private function payload(array $overrides = []): array
    {
        return [
            '_form' => 'add-place',
            'name' => 'Pantai Viovio',
            'type' => 'attraction',
            'lat' => '0.8654210',
            'lng' => '104.2145890',
            'address' => 'Jl. Trans Barelang, Sijantung, Galang, Batam',
            'kecamatan' => 'Galang',
            'estimated_cost_idr' => '15000',
            'estimated_visit_minutes' => '90',
            ...$overrides,
        ];
    }

    public function test_a_manual_place_is_stored_and_the_admin_lands_on_its_edit_page(): void
    {
        $category = Category::create(['slug' => 'pantai', 'name_id' => 'Pantai', 'name_en' => 'Beach']);

        $response = $this->actingAs($this->admin)
            ->post(route('admin.places.store'), $this->payload(['category_ids' => [$category->categories_id]]));

        $place = Place::where('name', 'Pantai Viovio')->firstOrFail();
        $response->assertRedirect(route('admin.places.edit', $place))->assertSessionHas('status');
        $this->assertSame('attraction', $place->type);
        $this->assertSame('manual', $place->source);
        $this->assertSame('Galang', $place->kecamatan);
        $this->assertSame(15000, $place->estimated_cost_idr);
        $this->assertSame(90, $place->estimated_visit_minutes);
        $this->assertSame([$category->categories_id], $place->categories->pluck('categories_id')->all());
    }

    public function test_zero_is_free_and_empty_is_unknown(): void
    {
        $this->actingAs($this->admin)
            ->post(route('admin.places.store'), $this->payload(['estimated_cost_idr' => '0']));
        $this->actingAs($this->admin)
            ->post(route('admin.places.store'), $this->payload(['name' => 'Kedai Baru', 'type' => 'culinary', 'estimated_cost_idr' => '']));

        $this->assertSame(0, Place::where('name', 'Pantai Viovio')->value('estimated_cost_idr'));
        $this->assertNull(Place::where('name', 'Kedai Baru')->value('estimated_cost_idr'));
    }

    public function test_missing_type_and_coordinates_come_back_with_indonesian_messages(): void
    {
        $this->actingAs($this->admin)
            ->from(route('admin.places.index'))
            ->post(route('admin.places.store'), $this->payload(['type' => '', 'lat' => '', 'lng' => '']))
            ->assertRedirect(route('admin.places.index'))
            ->assertSessionHasErrors([
                'type' => 'Pilih jenis tempat.',
                'lat' => 'Tentukan titik lokasi: cari lokasi atau isi garis lintang.',
            ]);

        $this->assertSame(0, Place::count());
    }

    public function test_the_list_reopens_the_modal_after_a_failed_save(): void
    {
        $this->actingAs($this->admin)
            ->from(route('admin.places.index'))
            ->followingRedirects()
            ->post(route('admin.places.store'), $this->payload(['name' => '']))
            ->assertOk()
            ->assertSee('data-reopen="1"', false)
            ->assertSee('Nama tempat wajib diisi.');
    }

    public function test_geocode_searches_inside_batam_and_matches_the_kecamatan(): void
    {
        Http::fake(['api.geoapify.com/v1/geocode/search*' => Http::response(['results' => [
            [
                'name' => 'Pantai Viovio', 'formatted' => 'Pantai Viovio, Sijantung, Galang, Batam',
                'lat' => 0.8654, 'lon' => 104.2146, 'suburb' => 'Sijantung', 'district' => 'Kecamatan Galang', 'city' => 'Batam',
            ],
            [
                'name' => 'Sei Beduk', 'formatted' => 'Sei Beduk, Batam', 'lat' => 1.05, 'lon' => 104.05, 'district' => 'Sei Beduk',
            ],
            [
                'formatted' => 'Jalan Tanpa Nama, Batam', 'address_line1' => 'Jalan Tanpa Nama', 'lat' => 1.1, 'lon' => 104.0,
            ],
        ]])]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.geocode', ['q' => 'viovio']))
            ->assertOk()
            ->assertJsonPath('results.0.kecamatan', 'Galang')
            ->assertJsonPath('results.0.lat', 0.8654)
            ->assertJsonPath('results.1.kecamatan', 'Seibeduk')
            ->assertJsonPath('results.2.name', 'Jalan Tanpa Nama')
            ->assertJsonPath('results.2.kecamatan', null);

        Http::assertSent(fn ($request) => str_contains($request->url(), 'text=viovio')
            && str_contains($request->url(), 'filter=rect%3A103.65%2C0.45%2C104.45%2C1.25'));
    }

    public function test_geocode_reports_a_provider_failure(): void
    {
        Http::fake(['api.geoapify.com/*' => Http::response(['message' => 'Invalid apiKey'], 401)]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.geocode', ['q' => 'viovio']))
            ->assertStatus(502)
            ->assertJsonStructure(['message']);
    }

    public function test_geocode_needs_three_letters(): void
    {
        $this->actingAs($this->admin)
            ->getJson(route('admin.places.geocode', ['q' => 'ab']))
            ->assertUnprocessable();
    }
}
