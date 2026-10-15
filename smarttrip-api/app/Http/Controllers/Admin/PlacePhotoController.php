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
            return back()->with('error', $exception->getMessage());
        }

        return back()->with('status', count($request->file('photos')).' foto diunggah.');
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
        $data = $request->validate(['image_url' => ['required', 'url:http,https', 'max:2000']]);

        try {
            $store->storeFromLink($place, $data['image_url']);
        } catch (RuntimeException $exception) {
            return back()->with('error', $exception->getMessage());
        }

        return back()->with('status', 'Foto dari Google Gambar ditambahkan.');
    }

    public function storeFromLink(Request $request, Place $place, PlacePhotoStore $store)
    {
        $data = $request->validate([
            'image_url' => ['required', 'url:http,https', 'max:2000'],
            'license_checked' => ['accepted'],
        ], [
            'image_url.required' => 'Isi alamat gambarnya.',
            'image_url.url' => 'Alamat gambar harus berupa tautan http:// atau https://.',
            'license_checked.accepted' => 'Centang konfirmasi bahwa foto ini memang tempatnya.',
        ]);

        try {
            $store->storeFromLink($place, $data['image_url']);
        } catch (RuntimeException $exception) {
            return back()->withInput()->with('error', $exception->getMessage());
        }

        return back()->with('status', 'Foto dari tautan ditambahkan.');
    }

    public function primary(Place $place, PlacePhoto $photo, PlacePhotoStore $store)
    {
        abort_unless($photo->places_id === $place->places_id, 404);

        $store->makePrimary($photo);

        return back()->with('status', 'Foto utama diganti.');
    }

    public function destroy(Place $place, PlacePhoto $photo, PlacePhotoStore $store)
    {
        abort_unless($photo->places_id === $place->places_id, 404);

        $store->delete($photo);

        return back()->with('status', 'Foto dihapus.');
    }
}
