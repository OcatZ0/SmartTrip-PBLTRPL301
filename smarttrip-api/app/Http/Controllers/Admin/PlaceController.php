<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Place;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * F021 (US13, docs/prd design spec Section 14) - CRUD places: list/search
 * (data Google + manual), tambah manual tempat yang tidak ada di Google,
 * form edit atribut kurasi (estimated_cost_idr, description_override,
 * description_en, estimated_visit_minutes, is_outdoor, kecamatan) +
 * kategori. Edit di sini otomatis kena log lewat LogsActivity di model
 * Place - "Riwayat Perubahan" (F023) tinggal baca dari situ.
 */
class PlaceController extends Controller
{
    public function index(Request $request)
    {
        $places = Place::query()
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.mb_strtolower($request->string('search')->trim()).'%';
                $q->whereRaw('LOWER(name) LIKE ?', [$term]);
            })
            ->when($request->filled('kecamatan'), fn ($q) => $q->where('kecamatan', $request->string('kecamatan')))
            ->orderByDesc('created_at')
            ->paginate(25)
            ->withQueryString();

        return view('admin.places.index', [
            'places' => $places,
            'search' => $request->string('search')->toString(),
            'selectedKecamatan' => $request->string('kecamatan')->toString(),
        ]);
    }

    public function create()
    {
        return view('admin.places.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'type' => ['required', Rule::in(['attraction', 'culinary', 'lodging'])],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['required', 'string', 'max:255'],
            'kecamatan' => ['nullable', 'string', 'max:255'],
            'description' => ['nullable', 'string'],
            'estimated_cost_idr' => ['nullable', 'integer', 'min:0'],
            'estimated_visit_minutes' => ['nullable', 'integer', 'min:1'],
            'is_outdoor' => ['sometimes', 'boolean'],
        ]);

        $place = Place::create([
            ...$data,
            'is_outdoor' => $request->boolean('is_outdoor'),
            'source' => 'manual',
            'business_status' => 'operational',
        ]);

        return redirect()->route('admin.places.edit', $place)->with('status', "\"{$place->name}\" ditambahkan.");
    }

    public function edit(Place $place)
    {
        $place->load(['categories', 'photos' => fn ($query) => $query->orderBy('sort_order')]);

        return view('admin.places.edit', [
            'place' => $place,
            'categories' => Category::orderBy('name_id')->get(),
            // F023: tab Riwayat Perubahan - baca dari activity_log yang
            // sudah mulai kecatat sejak F021.
            'activities' => $place->activitiesAsSubject()->with('causer')->latest()->get(),
        ]);
    }

    public function update(Request $request, Place $place)
    {
        $data = $request->validate([
            'kecamatan' => ['nullable', 'string', 'max:255'],
            'description_override' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],
            'estimated_cost_idr' => ['nullable', 'integer', 'min:0'],
            'estimated_visit_minutes' => ['nullable', 'integer', 'min:1'],
            'is_outdoor' => ['sometimes', 'boolean'],
            'category_ids' => ['sometimes', 'array'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')->whereNull('deleted_at')],
        ]);

        $place->update([
            'kecamatan' => $data['kecamatan'] ?? null,
            'description_override' => $data['description_override'] ?? null,
            'description_en' => $data['description_en'] ?? null,
            'estimated_cost_idr' => $data['estimated_cost_idr'] ?? null,
            'estimated_visit_minutes' => $data['estimated_visit_minutes'] ?? null,
            'is_outdoor' => $request->boolean('is_outdoor'),
            // US13: admin mengedit kategori (form ini satu-satunya tempat
            // kategori direview/dikonfirmasi manual) menandai tag AI sudah
            // dicek - lihat docs/prd design spec Section 5.
            'category_tags_reviewed' => true,
        ]);

        $place->categories()->sync($data['category_ids'] ?? []);

        return redirect()->route('admin.places.edit', $place)->with('status', "\"{$place->name}\" diperbarui.");
    }

    public function destroy(Place $place)
    {
        $place->delete();

        return redirect()->route('admin.places.index')->with('status', "\"{$place->name}\" dihapus.");
    }
}
