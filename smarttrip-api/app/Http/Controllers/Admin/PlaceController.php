<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/**
 * F020 - Admin dapat mengelola data tempat wisata (CRUD places)
 */
class PlaceController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->string('search')->trim()->toString();
        $selectedKecamatan = $request->string('kecamatan')->trim()->toString();
        $selectedType = $request->string('type')->trim()->toString();
        $selectedStatus = $request->string('status_data')->trim()->toString();

        $query = Place::query()->with(['categories', 'photos']);

        if (! empty($search)) {
            $term = '%'.mb_strtolower($search).'%';
            $query->where(function ($q) use ($term) {
                $q->whereRaw('LOWER(name) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(address) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(google_place_id) LIKE ?', [$term]);
            });
        }

        if (! empty($selectedKecamatan)) {
            $query->where('kecamatan', $selectedKecamatan);
        }

        if (! empty($selectedType)) {
            $query->where('type', $selectedType);
        }

        if (! empty($selectedStatus)) {
            if ($selectedStatus === 'siap_tampil') {
                $query->where('category_tags_reviewed', true);
            } elseif ($selectedStatus === 'butuh_lengkapi') {
                $query->where('category_tags_reviewed', false);
            }
        }

        $places = $query->orderByDesc('created_at')
            ->paginate(6)
            ->withQueryString();

        $totalPlacesCount = Place::count();
        $siapTampilCount = Place::where('category_tags_reviewed', true)->count();
        $butuhLengkapiCount = Place::where('category_tags_reviewed', false)->count();
        $kandidatCount = PlaceCandidate::where('status', 'pending')->count();
        $categories = Category::orderBy('name_id')->get();

        $kecamatanList = [
            'Sagulung',
            'Galang',
            'Bengkong',
            'Sekupang',
            'Galang Selatan',
            'Lubuk Baja',
            'Batam Kota',
            'Nongsa',
            'Batu Ampar',
            'Bulang',
            'Belakang Padang',
            'Seibeduk',
        ];

        return view('admin.places.index', [
            'places' => $places,
            'search' => $search,
            'selectedKecamatan' => $selectedKecamatan,
            'selectedType' => $selectedType,
            'selectedStatus' => $selectedStatus,
            'totalPlacesCount' => $totalPlacesCount,
            'siapTampilCount' => $siapTampilCount,
            'butuhLengkapiCount' => $butuhLengkapiCount,
            'kandidatCount' => $kandidatCount,
            'categories' => $categories,
            'kecamatanList' => $kecamatanList,
        ]);
    }

    public function create()
    {
        return view('admin.places.create', [
            'categories' => Category::orderBy('name_id')->get(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'category_ids' => ['nullable', 'array'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')],
            'kecamatan' => ['nullable', 'string', 'max:255'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['required', 'string', 'max:1000'],
            'photo_url' => ['nullable', 'string', 'max:2000'],
            'photo_file' => ['nullable', 'image', 'max:2048'],
            'estimated_cost_idr' => ['nullable', 'integer', 'min:0'],
            'is_free' => ['sometimes', 'boolean'],
            'estimated_visit_minutes' => ['nullable', 'integer', 'min:1'],
            'type' => ['required', 'string', Rule::in(['attraction', 'culinary', 'lodging'])],
            'description' => ['nullable', 'string'],
        ]);

        $photoUrl = $data['photo_url'] ?? null;
        if ($request->hasFile('photo_file')) {
            $path = $request->file('photo_file')->store('places', 'public');
            $photoUrl = asset('storage/'.$path);
        }

        if (empty($photoUrl)) {
            $photoUrl = 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=300&h=300&fit=crop';
        }

        $costIdr = $request->boolean('is_free') ? 0 : ($data['estimated_cost_idr'] ?? null);

        $place = Place::create([
            'google_place_id' => $data['google_place_id'] ?? null,
            'name' => $data['name'],
            'type' => $data['type'],
            'lat' => $data['lat'],
            'lng' => $data['lng'],
            'address' => $data['address'],
            'kecamatan' => $data['kecamatan'] ?? null,
            'photo_url' => $photoUrl,
            'description' => $data['description'] ?? null,
            'estimated_cost_idr' => $costIdr,
            'estimated_visit_minutes' => $data['estimated_visit_minutes'] ?? 60,
            'is_outdoor' => true,
            'category_tags_reviewed' => true,
            'source' => 'manual',
            'business_status' => 'operational',
            'rating' => 4.5,
            'review_count' => 1,
        ]);

        if (! empty($data['category_ids'])) {
            $place->categories()->sync($data['category_ids']);
        }

        return redirect()->route('admin.places.index')
            ->with('place_created_success', "\"{$place->name}\" berhasil ditambahkan.");
    }

    public function edit(Place $place)
    {
        return redirect()->route('admin.places.index', ['edit_id' => $place->places_id]);
    }

    public function update(Request $request, Place $place)
    {
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:255'],
            'kecamatan' => ['nullable', 'string', 'max:255'],
            'lat' => ['nullable', 'numeric', 'between:-90,90'],
            'lng' => ['nullable', 'numeric', 'between:-180,180'],
            'address' => ['nullable', 'string', 'max:1000'],
            'photo_url' => ['nullable', 'string', 'max:2000'],
            'photo_file' => ['nullable', 'image', 'max:2048'],
            'description_override' => ['nullable', 'string'],
            'description_en' => ['nullable', 'string'],
            'estimated_cost_idr' => ['nullable', 'integer', 'min:0'],
            'estimated_visit_minutes' => ['nullable', 'integer', 'min:1'],
            'is_outdoor' => ['sometimes', 'boolean'],
            'category_ids' => ['sometimes', 'array'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')->whereNull('deleted_at')],
        ]);

        $photoUrl = $place->photo_url;
        if ($request->hasFile('photo_file')) {
            $path = $request->file('photo_file')->store('places', 'public');
            $photoUrl = asset('storage/'.$path);
        } elseif (! empty($data['photo_url'])) {
            $photoUrl = $data['photo_url'];
        }

        $updateData = [
            'kecamatan' => $data['kecamatan'] ?? $place->kecamatan,
            'lat' => $data['lat'] ?? $place->lat,
            'lng' => $data['lng'] ?? $place->lng,
            'address' => $data['address'] ?? $place->address,
            'photo_url' => $photoUrl,
            'description_override' => $data['description_override'] ?? $place->description_override,
            'description_en' => $data['description_en'] ?? $place->description_en,
            'estimated_cost_idr' => $data['estimated_cost_idr'] ?? $place->estimated_cost_idr,
            'estimated_visit_minutes' => $data['estimated_visit_minutes'] ?? $place->estimated_visit_minutes,
            'is_outdoor' => $request->has('is_outdoor') ? $request->boolean('is_outdoor') : $place->is_outdoor,
            'category_tags_reviewed' => true,
        ];

        if (isset($data['name'])) {
            $updateData['name'] = $data['name'];
        }

        $place->update($updateData);

        $place->categories()->sync($request->input('category_ids', []));

        return redirect()->route('admin.places.index')
            ->with('status', "\"{$place->name}\" berhasil diperbarui.");
    }

    public function destroy(Place $place)
    {
        $placeName = $place->name;
        $place->delete();

        return redirect()->route('admin.places.index')
            ->with('status', "\"{$placeName}\" berhasil dihapus.");
    }

    public function activities(Place $place)
    {
        $activities = $place->activitiesAsSubject()
            ->with('causer')
            ->latest()
            ->take(30)
            ->get();

        return response()->json([
            'subject' => $place->name,
            'type' => 'Tempat Wisata',
            'activities' => $activities->map(function ($act) {
                return [
                    'id' => $act->id,
                    'event' => $act->event,
                    'causer' => $act->causer?->name ?? 'Admin Kurator',
                    'created_at' => $act->created_at->format('d M Y, H:i'),
                    'human_time' => $act->created_at->diffForHumans(),
                    'old' => $act->properties['old'] ?? [],
                    'attributes' => $act->properties['attributes'] ?? [],
                ];
            }),
        ]);
    }
}
