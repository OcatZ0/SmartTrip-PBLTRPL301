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

    private const OPENVERSE_ID = '4bc43a04-ef46-4544-a0c1-63c63f56e276';

    private User $admin;

    private Place $place;

    protected function setUp(): void
    {
        parent::setUp();

        Storage::fake('public');
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

    private function openverseImage(array $overrides = []): array
    {
        return array_merge([
            'id' => self::OPENVERSE_ID,
            'title' => 'Masjid Agung Batam',
            'creator' => 'Si Gam',
            'license' => 'by-sa',
            'license_version' => '4.0',
            'license_url' => 'https://creativecommons.org/licenses/by-sa/4.0/',
            'foreign_landing_url' => 'https://commons.wikimedia.org/w/index.php?curid=1',
            'url' => 'https://upload.wikimedia.org/masjid.jpg',
            'thumbnail' => 'https://api.openverse.org/v1/images/'.self::OPENVERSE_ID.'/thumb/',
            'source' => 'wikimedia',
        ], $overrides);
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
        $this->assertNull($photos->first()->credit);
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

    public function test_the_openverse_search_returns_normalized_candidates_as_json(): void
    {
        Http::fake(['api.openverse.org/v1/images/*' => Http::response(['results' => [
            $this->openverseImage(),
            $this->openverseImage(['id' => 'x', 'license' => 'by-nc-sa', 'license_version' => '2.0']),
        ]])]);

        $response = $this->actingAs($this->admin)
            ->getJson("/admin/places/{$this->place->places_id}/photos/openverse?q=Masjid+Agung+Batam");

        $response->assertOk()
            ->assertJsonPath('results.0.license', 'CC BY-SA 4.0')
            ->assertJsonPath('results.0.commercial', true)
            ->assertJsonPath('results.0.creator', 'Si Gam')
            ->assertJsonPath('results.1.commercial', false);
        Http::assertSent(fn ($request) => $request['q'] === 'Masjid Agung Batam');
    }

    public function test_an_openverse_outage_is_reported_as_json(): void
    {
        Http::fake(['api.openverse.org/*' => Http::response([], 503)]);

        $this->actingAs($this->admin)
            ->getJson("/admin/places/{$this->place->places_id}/photos/openverse?q=x")
            ->assertStatus(502)
            ->assertJsonPath('message', 'Openverse gagal (503).');
    }

    public function test_picking_an_openverse_photo_saves_it_with_credit_from_openverse_itself(): void
    {
        Http::fake([
            'api.openverse.org/v1/images/'.self::OPENVERSE_ID.'/' => Http::response($this->openverseImage()),
            'upload.wikimedia.org/*' => Http::response($this->jpegBytes(1000, 700)),
        ]);

        $response = $this->actingAs($this->admin)->post("/admin/places/{$this->place->places_id}/photos/openverse", [
            'openverse_id' => self::OPENVERSE_ID,
            // Ignored: the credit is read from Openverse, not the form.
            'credit' => 'Penipu',
        ]);

        $response->assertRedirect()->assertSessionHas('status');
        $photo = $this->place->photos()->sole();
        $this->assertSame('Si Gam', $photo->credit);
        $this->assertSame('CC BY-SA 4.0', $photo->license);
        $this->assertSame('https://commons.wikimedia.org/w/index.php?curid=1', $photo->source_url);
        $this->assertSame($photo->photo_url, $this->place->fresh()->photo_url);
    }

    public function test_an_invalid_openverse_id_is_refused_without_calling_openverse(): void
    {
        Http::fake();

        $this->actingAs($this->admin)
            ->post("/admin/places/{$this->place->places_id}/photos/openverse", ['openverse_id' => '../../etc'])
            ->assertSessionHas('error', 'ID foto Openverse tidak valid.');

        Http::assertNothingSent();
    }

    public function test_making_a_photo_primary_reorders_and_updates_the_thumbnail(): void
    {
        foreach (['a', 'b', 'c'] as $index => $name) {
            PlacePhoto::create(['places_id' => $this->place->places_id, 'photo_url' => "{$name}.jpg", 'sort_order' => $index]);
        }
        $this->place->update(['photo_url' => 'a.jpg']);
        $third = PlacePhoto::where('photo_url', 'c.jpg')->first();

        $this->actingAs($this->admin)
            ->post("/admin/places/{$this->place->places_id}/photos/{$third->place_photos_id}/primary")
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
            ->getJson("/admin/places/{$this->place->places_id}/photos/openverse?q=x")
            ->assertForbidden();
    }

    public function test_the_edit_page_shows_photos_with_their_credit(): void
    {
        PlacePhoto::create([
            'places_id' => $this->place->places_id, 'photo_url' => 'a.jpg', 'sort_order' => 0,
            'credit' => 'Si Gam', 'license' => 'CC BY-SA 4.0', 'source_url' => 'https://commons.wikimedia.org/x',
        ]);

        $this->actingAs($this->admin)
            ->get("/admin/places/{$this->place->places_id}/edit")
            ->assertOk()
            ->assertSee('Foto Tempat')
            ->assertSee('Si Gam, CC BY-SA 4.0')
            ->assertSee('Cari foto berlisensi bebas (Openverse)');
    }

    public function test_the_place_detail_api_returns_photo_credits(): void
    {
        PlacePhoto::create([
            'places_id' => $this->place->places_id, 'photo_url' => 'a.jpg', 'sort_order' => 0,
            'credit' => 'Si Gam', 'license' => 'CC BY-SA 4.0', 'source_url' => 'https://commons.wikimedia.org/x',
        ]);

        $this->getJson("/api/places/{$this->place->places_id}")
            ->assertOk()
            ->assertJsonPath('data.photos.0.credit', 'Si Gam')
            ->assertJsonPath('data.photos.0.license', 'CC BY-SA 4.0')
            ->assertJsonPath('data.photos.0.source_url', 'https://commons.wikimedia.org/x');
    }
}
