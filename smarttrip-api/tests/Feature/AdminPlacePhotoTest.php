<?php

namespace Tests\Feature;

use App\Models\Place;
use App\Models\PlacePhoto;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class AdminPlacePhotoTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    private Place $place;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
        config(['services.serpapi.api_key' => 'test-key']);
        $this->admin = User::factory()->create(['role' => 'admin']);
        $this->place = Place::create([
            'name' => 'Masjid Agung Batam', 'type' => 'attraction', 'lat' => 1.1264, 'lng' => 104.0534,
            'address' => 'Batam Centre', 'source' => 'manual',
        ]);
    }

    private function jpegBytes(int $width = 2400, int $height = 1200): string
    {
        $image = imagecreatetruecolor($width, $height);
        ob_start();
        imagejpeg($image);

        return (string) ob_get_clean();
    }


    public function test_the_admin_can_upload_photos_and_the_first_becomes_the_catalog_thumbnail(): void
    {
        $response = $this->actingAs($this->admin)->post("/admin/places/{$this->place->places_id}/photos", [
            'photos' => [
                UploadedFile::fake()->createWithContent('a.jpg', $this->jpegBytes()),
                UploadedFile::fake()->createWithContent('b.jpg', $this->jpegBytes(800, 600)),
            ],
        ]);

        $response->assertRedirect();
        $photos = $this->place->photos()->orderBy('sort_order')->get();
        $this->assertSame([0, 1], $photos->pluck('sort_order')->all());
        $this->assertSame($photos->first()->photo_url, $this->place->fresh()->photo_url);

        // Shrunk to at most 1600 px on the longest side.
        $path = str_replace(Storage::disk('public')->url(''), '', $photos->first()->photo_url);
        [$width] = getimagesizefromstring(Storage::disk('public')->get(ltrim($path, '/')));
        $this->assertSame(1600, $width);
    }

    public function test_a_file_that_is_not_an_image_is_rejected(): void
    {
        $response = $this->actingAs($this->admin)->post("/admin/places/{$this->place->places_id}/photos", [
            'photos' => [UploadedFile::fake()->create('notes.pdf', 10, 'application/pdf')],
        ]);

        $response->assertSessionHasErrors('photos.0');
        $this->assertSame(0, $this->place->photos()->count());
    }



    private function googleImage(int $position): array
    {
        return [
            'position' => $position,
            'title' => "Masjid Agung Batam {$position}",
            'source' => 'Wikipedia',
            'link' => "https://id.wikipedia.org/wiki/Masjid_{$position}",
            'original' => "https://upload.wikimedia.org/masjid-{$position}.jpg",
            'thumbnail' => "https://serpapi.com/thumb-{$position}.jpg",
        ];
    }

    public function test_the_google_images_search_returns_at_most_nine_results(): void
    {
        Http::fake(['serpapi.com/*' => Http::response(['images_results' => array_map(fn ($position) => $this->googleImage($position), range(1, 12))])]);

        $response = $this->actingAs($this->admin)
            ->getJson(route('admin.places.photos.google', [$this->place, 'q' => 'Masjid Agung Batam']));

        $response->assertOk()
            ->assertJsonCount(9, 'results')
            ->assertJsonPath('results.0.url', 'https://upload.wikimedia.org/masjid-1.jpg')
            ->assertJsonPath('results.0.source_url', 'https://id.wikipedia.org/wiki/Masjid_1');
        Http::assertSent(fn ($request) => $request['engine'] === 'google_images'
            && $request['q'] === 'Masjid Agung Batam'
            && $request['api_key'] === 'test-key');
    }

    public function test_the_same_google_images_search_is_cached_for_a_day(): void
    {
        Http::fake(['serpapi.com/*' => Http::response(['images_results' => [$this->googleImage(1)]])]);

        foreach (['Masjid Agung Batam', ' masjid agung batam '] as $query) {
            $this->actingAs($this->admin)
                ->getJson(route('admin.places.photos.google', [$this->place, 'q' => $query]))
                ->assertOk();
        }

        Http::assertSentCount(1);
    }

    public function test_the_google_images_search_needs_an_api_key(): void
    {
        config(['services.serpapi.api_key' => null]);
        Http::fake();

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.photos.google', [$this->place, 'q' => 'x']))
            ->assertStatus(502)
            ->assertJsonPath('message', 'SERPAPI_API_KEY belum diisi di .env.');

        Http::assertNothingSent();
    }

    public function test_a_used_up_serpapi_quota_is_reported_and_not_cached(): void
    {
        Http::fake(['serpapi.com/*' => Http::sequence()
            ->push(['error' => 'Your account has run out of searches.'], 429)
            ->push(['images_results' => [$this->googleImage(1)]])]);

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.photos.google', [$this->place, 'q' => 'x']))
            ->assertStatus(502)
            ->assertJsonPath('message', 'Kuota pencarian SerpApi bulan ini sudah habis.');

        $this->actingAs($this->admin)
            ->getJson(route('admin.places.photos.google', [$this->place, 'q' => 'x']))
            ->assertOk()
            ->assertJsonCount(1, 'results');
    }

    public function test_several_google_images_results_can_be_picked_at_once(): void
    {
        // Public IP literals, so the address check needs no DNS lookup in tests.
        Http::fake(['93.184.216.34/*' => Http::response($this->jpegBytes(1000, 700))]);

        $this->actingAs($this->admin)
            ->post(route('admin.places.photos.google.store', $this->place), ['image_urls' => [
                'http://93.184.216.34/masjid-1.jpg', 'http://93.184.216.34/masjid-2.jpg', 'http://93.184.216.34/masjid-3.jpg',
            ]])
            ->assertRedirect()
            ->assertSessionHas('status', '3 foto dari Google Gambar ditambahkan.');

        $this->assertSame([0, 1, 2], $this->place->photos()->orderBy('sort_order')->pluck('sort_order')->all());
        $this->assertSame($this->place->photos()->orderBy('sort_order')->value('photo_url'), $this->place->fresh()->photo_url);
    }

    public function test_one_failed_download_does_not_drop_the_other_picks(): void
    {
        Http::fake([
            '93.184.216.34/ok.jpg' => Http::response($this->jpegBytes(1000, 700)),
            '93.184.216.34/blocked.jpg' => Http::response('', 403),
        ]);

        $this->actingAs($this->admin)
            ->post(route('admin.places.photos.google.store', $this->place), ['image_urls' => [
                'http://93.184.216.34/blocked.jpg', 'http://93.184.216.34/ok.jpg',
            ]])
            ->assertSessionHas('status', '1 foto dari Google Gambar ditambahkan. 1 foto gagal diunduh, pilih foto lain.');

        $this->assertSame(1, $this->place->photos()->count());
    }

    public function test_picking_needs_at_least_one_and_at_most_nine_photos(): void
    {
        Http::fake();

        $this->actingAs($this->admin)
            ->post(route('admin.places.photos.google.store', $this->place), ['image_urls' => []])
            ->assertSessionHasErrors('image_urls');

        $tooMany = array_map(fn ($number) => "http://93.184.216.34/{$number}.jpg", range(1, 10));
        $this->actingAs($this->admin)
            ->post(route('admin.places.photos.google.store', $this->place), ['image_urls' => $tooMany])
            ->assertSessionHasErrors('image_urls');

        Http::assertNothingSent();
    }

    public function test_a_google_images_result_on_the_local_network_is_refused(): void
    {
        Http::fake();

        $this->actingAs($this->admin)
            ->post(route('admin.places.photos.google.store', $this->place), ['image_urls' => ['http://192.168.1.10/a.jpg']])
            ->assertSessionHas('error', 'Foto tidak bisa ditambahkan. Alamat gambar harus dari internet, bukan jaringan lokal.');

        Http::assertNothingSent();
        $this->assertSame(0, $this->place->photos()->count());
    }

    private function linkPayload(array $overrides = []): array
    {
        // A public IP literal, so the address check needs no DNS lookup in tests.
        return array_merge([
            'image_url' => 'http://93.184.216.34/masjid.jpg',
        ], $overrides);
    }

    public function test_a_photo_from_a_link_is_saved_and_becomes_the_catalog_thumbnail(): void
    {
        Http::fake(['93.184.216.34/*' => Http::response($this->jpegBytes(1000, 700))]);

        $response = $this->actingAs($this->admin)->post(route('admin.places.photos.link.store', $this->place), $this->linkPayload());

        $response->assertRedirect()->assertSessionHas('status');
        $photo = $this->place->photos()->sole();
        $this->assertSame($photo->photo_url, $this->place->fresh()->photo_url);
    }

    public function test_a_photo_from_a_link_needs_an_image_url(): void
    {
        Http::fake();

        $response = $this->actingAs($this->admin)->post(
            route('admin.places.photos.link.store', $this->place),
            $this->linkPayload(['image_url' => '']),
        );

        $response->assertSessionHasErrors(['image_url']);
        Http::assertNothingSent();
        $this->assertSame(0, $this->place->photos()->count());
    }

    public function test_a_photo_link_to_this_machine_or_the_local_network_is_refused(): void
    {
        Http::fake();

        foreach (['http://127.0.0.1/a.jpg', 'http://192.168.200.150/a.jpg', 'http://localhost/a.jpg', 'http://[::1]/a.jpg'] as $url) {
            $this->actingAs($this->admin)
                ->post(route('admin.places.photos.link.store', $this->place), $this->linkPayload(['image_url' => $url]))
                ->assertRedirect()
                ->assertSessionHas('error', 'Alamat gambar harus dari internet, bukan jaringan lokal.');
        }

        Http::assertNothingSent();
        $this->assertSame(0, $this->place->photos()->count());
    }

    public function test_a_photo_link_that_is_not_an_image_is_reported(): void
    {
        Http::fake(['93.184.216.34/*' => Http::response('<html>bukan gambar</html>')]);

        $this->actingAs($this->admin)
            ->post(route('admin.places.photos.link.store', $this->place), $this->linkPayload())
            ->assertRedirect()
            ->assertSessionHas('error', 'File bukan gambar JPG, PNG, atau WebP yang bisa dibaca.');

        $this->assertSame(0, $this->place->photos()->count());
    }




    public function test_saving_the_edit_form_with_a_new_main_photo_reorders_and_updates_the_thumbnail(): void
    {
        foreach (['a', 'b', 'c'] as $index => $name) {
            PlacePhoto::create(['places_id' => $this->place->places_id, 'photo_url' => "{$name}.jpg", 'sort_order' => $index]);
        }
        $this->place->update(['photo_url' => 'a.jpg']);
        $third = PlacePhoto::where('photo_url', 'c.jpg')->first();

        // "Jadikan utama" only picks the photo; it is applied by "Simpan perubahan".
        $this->actingAs($this->admin)
            ->put("/admin/places/{$this->place->places_id}", ['primary_photo_id' => $third->place_photos_id])
            ->assertRedirect();

        $this->assertSame(['c.jpg', 'a.jpg', 'b.jpg'], $this->place->photos()->orderBy('sort_order')->pluck('photo_url')->all());
        $this->assertSame([0, 1, 2], $this->place->photos()->orderBy('sort_order')->pluck('sort_order')->all());
        $this->assertSame('c.jpg', $this->place->fresh()->photo_url);
    }

    public function test_deleting_the_last_photo_clears_the_thumbnail_and_the_file(): void
    {
        $this->actingAs($this->admin)->post("/admin/places/{$this->place->places_id}/photos", [
            'photos' => [UploadedFile::fake()->createWithContent('a.jpg', $this->jpegBytes(400, 300))],
        ]);
        $photo = $this->place->photos()->sole();
        $this->assertCount(1, Storage::disk('public')->allFiles());

        $this->actingAs($this->admin)
            ->delete("/admin/places/{$this->place->places_id}/photos/{$photo->place_photos_id}")
            ->assertRedirect();

        $this->assertNull($this->place->fresh()->photo_url);
        $this->assertCount(0, Storage::disk('public')->allFiles());
    }

    public function test_a_photo_of_another_place_cannot_be_touched_through_this_place(): void
    {
        $other = Place::create([
            'name' => 'Lain', 'type' => 'attraction', 'lat' => 1, 'lng' => 104, 'address' => 'x', 'source' => 'manual',
        ]);
        $photo = PlacePhoto::create(['places_id' => $other->places_id, 'photo_url' => 'x.jpg', 'sort_order' => 0]);

        $this->actingAs($this->admin)
            ->delete("/admin/places/{$this->place->places_id}/photos/{$photo->place_photos_id}")
            ->assertNotFound();

        $this->assertNotNull($photo->fresh());
    }

    public function test_photo_routes_are_admin_only(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $this->actingAs($user)
            ->getJson(route('admin.places.photos.google', [$this->place, 'q' => 'x']))
            ->assertForbidden();
    }

    public function test_the_edit_page_shows_the_photos(): void
    {
        PlacePhoto::create(['places_id' => $this->place->places_id, 'photo_url' => 'a.jpg', 'sort_order' => 0]);

        $this->actingAs($this->admin)
            ->get("/admin/places/{$this->place->places_id}/edit")
            ->assertOk()
            ->assertSee('Foto Tempat')
            ->assertSee('src="a.jpg"', false)
            ->assertSee('Cari di Google Gambar')
            ->assertSee('Tambah dari tautan');
    }

    public function test_the_place_detail_api_returns_only_the_photo_url(): void
    {
        PlacePhoto::create(['places_id' => $this->place->places_id, 'photo_url' => 'a.jpg', 'sort_order' => 0]);

        $this->getJson("/api/places/{$this->place->places_id}")
            ->assertOk()
            ->assertJsonPath('data.photos', [['url' => 'a.jpg']]);
    }
}
