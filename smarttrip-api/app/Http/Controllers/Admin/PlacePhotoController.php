<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlacePhoto;
use App\Services\Places\OpenverseClient;
use App\Services\Places\PlacePhotoStore;
use Illuminate\Http\Request;
use RuntimeException;

/**
 * F021 - foto tempat di form edit admin: unggah sendiri, atau cari foto
 * berlisensi Creative Commons di Openverse lalu pilih yang benar (kredit dan
 * lisensinya ikut tersimpan). Foto urutan pertama jadi thumbnail katalog.
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
        } catch (RuntimeException $e) {
            return back()->with('error', $e->getMessage());
        }

        return back()->with('status', count($request->file('photos')).' foto diunggah.');
    }

    /**
     * AJAX: Openverse candidates for the admin to pick from.
     */
    public function search(Request $request, Place $place, OpenverseClient $openverse)
    {
        $data = $request->validate(['q' => ['required', 'string', 'max:100']]);

        try {
            return response()->json(['results' => $openverse->search($data['q'])]);
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 502);
        }
    }

    public function storeFromOpenverse(Request $request, Place $place, OpenverseClient $openverse, PlacePhotoStore $store)
    {
        $data = $request->validate(['openverse_id' => ['required', 'string', 'max:64']]);

        try {
            $store->storeFromOpenverse($place, $openverse->find($data['openverse_id']));
        } catch (RuntimeException $e) {
            return back()->with('error', $e->getMessage());
        }

        return back()->with('status', 'Foto dari Openverse ditambahkan beserta kredit dan lisensinya.');
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
