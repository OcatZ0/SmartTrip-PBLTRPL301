<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlacePhoto;
use App\Services\Places\GoogleImagesClient;
use App\Services\Places\PlacePhotoStore;
use Illuminate\Http\Request;
use RuntimeException;

/**
 * F021 - foto tempat di form edit admin: unggah sendiri, cari di Google
 * Gambar (lewat SerpApi) lalu pilih yang benar, atau tempel tautan foto.
 * Foto urutan pertama jadi thumbnail katalog.
 */
class PlacePhotoController extends Controller
{
    public function store(Request $request, Place $place, PlacePhotoStore $store)
    {
        $request->validate([
            'photos' => ['required', 'array', 'max:10'],
            'photos.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:8192'],
        ]);

        try {
            foreach ($request->file('photos') as $file) {
                $store->storeUpload($place, $file);
            }
        } catch (RuntimeException $exception) {
            return $this->answer($request, $place, $exception->getMessage(), failed: true);
        }

        return $this->answer($request, $place, count($request->file('photos')).' foto diunggah.');
    }

    /**
     * AJAX: Google Images candidates for the admin to pick from.
     */
    public function search(Request $request, Place $place, GoogleImagesClient $googleImages)
    {
        $data = $request->validate(['q' => ['required', 'string', 'max:100']]);

        try {
            return response()->json(['results' => $googleImages->search($data['q'])]);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 502);
        }
    }

    public function storeFromGoogle(Request $request, Place $place, PlacePhotoStore $store)
    {
        $data = $request->validate([
            'image_urls' => ['required', 'array', 'max:'.GoogleImagesClient::MAX_RESULTS],
            'image_urls.*' => ['required', 'distinct', 'url:http,https', 'max:2000'],
        ], [
            'image_urls.required' => 'Pilih minimal satu foto.',
        ]);

        // One host blocking downloads should not cost the admin the others.
        $savedCount = 0;
        $failures = [];
        foreach ($data['image_urls'] as $imageUrl) {
            try {
                $store->storeFromLink($place, $imageUrl);
                $savedCount++;
            } catch (RuntimeException $exception) {
                $failures[] = $exception->getMessage();
            }
        }

        if ($savedCount === 0) {
            return $this->answer($request, $place, 'Foto tidak bisa ditambahkan. '.$failures[0], failed: true);
        }

        $status = "{$savedCount} foto dari Google Gambar ditambahkan.";
        if ($failures !== []) {
            $status .= ' '.count($failures).' foto gagal diunduh, pilih foto lain.';
        }

        return $this->answer($request, $place, $status);
    }

    public function storeFromLink(Request $request, Place $place, PlacePhotoStore $store)
    {
        $data = $request->validate([
            'image_url' => ['required', 'url:http,https', 'max:2000'],
        ], [
            'image_url.required' => 'Isi alamat gambarnya.',
            'image_url.url' => 'Alamat gambar harus berupa tautan http:// atau https://.',
        ]);

        try {
            $store->storeFromLink($place, $data['image_url']);
        } catch (RuntimeException $exception) {
            if (! $request->expectsJson()) {
                return back()->withInput()->with('error', $exception->getMessage());
            }

            return $this->answer($request, $place, $exception->getMessage(), failed: true);
        }

        return $this->answer($request, $place, 'Foto dari tautan ditambahkan.');
    }

    public function destroy(Request $request, Place $place, PlacePhoto $photo, PlacePhotoStore $store)
    {
        abort_unless($photo->places_id === $place->places_id, 404);

        $store->delete($photo);

        return $this->answer($request, $place, 'Foto dihapus.');
    }

    /**
     * The edit page sends these forms in the background (Accept: JSON) and
     * redraws the photo cards from the answer; a plain form post still
     * goes back with a flash message.
     */
    private function answer(Request $request, Place $place, string $message, bool $failed = false)
    {
        if (! $request->expectsJson()) {
            return back()->with($failed ? 'error' : 'status', $message);
        }

        $place->load(['photos' => fn ($query) => $query->orderBy('sort_order')]);

        return response()->json([
            'message' => $message,
            'html' => view('admin.places.photo-grid', ['place' => $place])->render(),
            'count' => $place->photos->count(),
            'primary_url' => $place->photos->first()?->photo_url,
        ], $failed ? 422 : 200);
    }
}
