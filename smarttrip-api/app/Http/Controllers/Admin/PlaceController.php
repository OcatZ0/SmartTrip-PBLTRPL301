<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Services\Places\GeminiKeywordSuggestionClient;
use App\Services\Places\GeminiPriceEstimateClient;
use App\Services\Places\GeoapifyPlacesClient;
use App\Services\Places\PlacePhotoStore;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use RuntimeException;

/**
 * F020 - Admin dapat mengelola data tempat wisata (CRUD places)
 */
class PlaceController extends Controller
{
    private const KECAMATAN_LIST = [
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

    public function index(Request $request)
    {
        $search = $request->string('search')->trim()->toString();
        $selectedKecamatan = $request->string('kecamatan')->trim()->toString();
        $selectedType = $request->string('type')->trim()->toString();
        $selectedStatus = $request->string('status_data')->trim()->toString();

        // Review count and average feed ratingBlend(), the rating the app shows.
        $query = Place::query()->with(['categories', 'photos'])->withCount('reviews')->withAvg('reviews', 'rating');

        if (! empty($search)) {
            $term = '%'.mb_strtolower($search).'%';
            $query->where(function ($searchQuery) use ($term) {
                $searchQuery->whereRaw('LOWER(name) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(address) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(external_place_id) LIKE ?', [$term]);
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
            'kecamatanList' => self::KECAMATAN_LIST,
        ]);
    }

    public function create()
    {
        return view('admin.places.create', [
            'categories' => Category::orderBy('name_id')->get(),
        ]);
    }

    /**
     * The "Tambah Tempat Manual" modal on the places list. Only what is needed
     * to put the place on the map; photos, descriptions and search keywords
     * are added on the edit page the admin lands on next.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'type' => ['required', 'string', Rule::in(['attraction', 'culinary', 'lodging'])],
            'category_ids' => ['nullable', 'array'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')],
            'kecamatan' => ['nullable', 'string', 'max:255'],
            'lat' => ['required', 'numeric', 'between:-90,90'],
            'lng' => ['required', 'numeric', 'between:-180,180'],
            'address' => ['required', 'string', 'max:1000'],
            'estimated_cost_idr' => ['nullable', 'integer', 'min:0'],
            'estimated_visit_minutes' => ['nullable', 'integer', 'min:15', 'max:1440'],
        ], [
            'name.required' => 'Nama tempat wajib diisi.',
            'type.required' => 'Pilih jenis tempat.',
            'type.in' => 'Pilih jenis tempat.',
            'lat.required' => 'Tentukan titik lokasi: cari lokasi atau isi garis lintang.',
            'lat.numeric' => 'Garis lintang harus angka, misalnya 1.0456.',
            'lat.between' => 'Garis lintang harus di antara -90 dan 90.',
            'lng.required' => 'Tentukan titik lokasi: cari lokasi atau isi garis bujur.',
            'lng.numeric' => 'Garis bujur harus angka, misalnya 104.0305.',
            'lng.between' => 'Garis bujur harus di antara -180 dan 180.',
            'address.required' => 'Alamat wajib diisi.',
            'estimated_cost_idr.integer' => 'Biaya harus angka bulat dalam rupiah.',
            'estimated_cost_idr.min' => 'Biaya tidak boleh negatif.',
            'estimated_visit_minutes.integer' => 'Lama kunjungan harus angka menit.',
            'estimated_visit_minutes.min' => 'Lama kunjungan minimal 15 menit.',
            'estimated_visit_minutes.max' => 'Lama kunjungan maksimal 1440 menit (24 jam).',
        ]);

        $place = Place::create([
            'name' => $data['name'],
            'type' => $data['type'],
            'lat' => $data['lat'],
            'lng' => $data['lng'],
            'address' => $data['address'],
            'kecamatan' => $data['kecamatan'] ?? null,
            // 0 is free, null is not known yet (same as the edit page).
            'estimated_cost_idr' => $data['estimated_cost_idr'] ?? null,
            'estimated_visit_minutes' => $data['estimated_visit_minutes'] ?? 60,
            'is_outdoor' => true,
            'category_tags_reviewed' => true,
            'source' => 'manual',
            'business_status' => 'operational',
            // No rating: a manual place has no Google rating, and the
            // itinerary ranking (PlaceRatingEstimator) handles null.
        ]);

        if (! empty($data['category_ids'])) {
            $place->categories()->sync($data['category_ids']);
        }

        return redirect()->route('admin.places.edit', $place)
            ->with('status', "\"{$place->name}\" ditambahkan. Lengkapi foto, deskripsi dan kata kunci pencarian di bawah.");
    }

    /**
     * Location search for the "Tambah Tempat Manual" modal. Each result
     * carries the kecamatan its area names match, when one does.
     */
    public function geocode(Request $request, GeoapifyPlacesClient $geoapify)
    {
        $data = $request->validate(['q' => ['required', 'string', 'min:3', 'max:200']]);

        try {
            $results = $geoapify->geocode($data['q']);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 502);
        }

        return response()->json([
            'results' => array_map(fn (array $result) => [
                'name' => $result['name'],
                'address' => $result['address'],
                'lat' => $result['lat'],
                'lng' => $result['lng'],
                'kecamatan' => self::matchKecamatan($result['areas']),
            ], $results),
        ]);
    }

    /**
     * "Kecamatan Sei Beduk" and "Seibeduk" both match Seibeduk.
     */
    private static function matchKecamatan(array $areas): ?string
    {
        $normalize = fn (string $text) => preg_replace('/[^a-z]/', '', str_replace('kecamatan', '', mb_strtolower($text)));

        foreach ($areas as $area) {
            foreach (self::KECAMATAN_LIST as $kecamatan) {
                if ($normalize($area) === $normalize($kecamatan)) {
                    return $kecamatan;
                }
            }
        }

        return null;
    }

    public function edit(Place $place)
    {
        $place->load(['categories', 'photos' => fn ($query) => $query->orderBy('sort_order')]);
        $place->loadCount(['wishlistedIn', 'itineraryItems']);

        return view('admin.places.edit', [
            'place' => $place,
            'categories' => Category::orderBy('name_id')->get(),
            // F023: tab Riwayat Perubahan - baca dari activity_log yang
            // sudah mulai kecatat sejak F021.
            'activities' => $place->activitiesAsSubject()->with('causer')->latest()->get(),
        ]);
    }

    public function update(Request $request, Place $place, PlacePhotoStore $photos)
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
            'category_tags_reviewed' => ['sometimes', 'boolean'],
            'category_ids' => ['sometimes', 'array'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')->whereNull('deleted_at')],
            'search_keywords' => ['nullable', 'string', 'max:1000'],
            // "Jadikan utama" on Foto Tempat: applied with the rest of the form.
            'primary_photo_id' => ['nullable', 'integer', Rule::exists('place_photos', 'place_photos_id')->where('places_id', $place->places_id)],
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
            // A sent but emptied description clears the override, so the app falls back to the generated one.
            'description_override' => array_key_exists('description_override', $data) ? $data['description_override'] : $place->description_override,
            'description_en' => array_key_exists('description_en', $data) ? $data['description_en'] : $place->description_en,
            'estimated_cost_idr' => $data['estimated_cost_idr'] ?? $place->estimated_cost_idr,
            'estimated_visit_minutes' => $data['estimated_visit_minutes'] ?? $place->estimated_visit_minutes,
            'is_outdoor' => $request->has('is_outdoor') ? $request->boolean('is_outdoor') : $place->is_outdoor,
            // The list popup has no checkbox, so saving there still counts as reviewing the tags.
            'category_tags_reviewed' => $request->has('category_tags_reviewed') ? $request->boolean('category_tags_reviewed') : true,
        ];

        if (isset($data['name'])) {
            $updateData['name'] = $data['name'];
        }

        // Only the edit page sends keywords; the list popup leaves them alone.
        if ($request->exists('search_keywords')) {
            $updateData['search_keywords'] = Place::normalizeSearchKeywords($data['search_keywords']);
        }

        $place->update($updateData);

        // After the update, so the thumbnail it syncs is the one saved.
        $primary = isset($data['primary_photo_id']) ? $place->photos()->find($data['primary_photo_id']) : null;
        if ($primary && ! $primary->is($place->photos()->orderBy('sort_order')->first())) {
            $photos->makePrimary($primary);
        }

        $place->categories()->sync($request->input('category_ids', []));

        // Back to the list popup or the full edit page, whichever sent it.
        return redirect()->back()
            ->with('status', "\"{$place->name}\" berhasil diperbarui.");
    }

    /**
     * AJAX: Gemini's price estimate for the admin to use or ignore.
     */
    public function estimatePrice(Place $place, GeminiPriceEstimateClient $priceEstimate)
    {
        try {
            return response()->json($priceEstimate->estimate($place));
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 502);
        }
    }

    /**
     * AJAX: Gemini's search keyword suggestions for this place; the admin
     * edits them before saving.
     */
    public function suggestKeywords(Place $place, GeminiKeywordSuggestionClient $suggestions)
    {
        try {
            return response()->json(['keywords' => $suggestions->suggest($place->load('categories'))]);
        } catch (RuntimeException $exception) {
            return response()->json(['message' => $exception->getMessage()], 502);
        }
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
                    // activitylog v5 keeps the diff in attribute_changes.
                    'old' => $act->attribute_changes?->get('old') ?? [],
                    'attributes' => $act->attribute_changes?->get('attributes') ?? [],
                ];
            }),
        ]);
    }
}
