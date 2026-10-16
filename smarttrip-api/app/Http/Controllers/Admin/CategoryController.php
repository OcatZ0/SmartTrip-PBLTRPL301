<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

/**
 * F021 - Admin dapat mengelola kategori tempat wisata (CRUD categories lewat Modal UI)
 */
class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->string('search')->trim()->toString();
        $editId = $request->integer('edit_id');

        // Up to 3 place names per category for the edit popup's note.
        $query = Category::query()
            ->withCount('places')
            ->with(['places' => fn ($places) => $places->select('places.places_id', 'places.name')->orderBy('places.name')->limit(3)]);

        if (! empty($search)) {
            $term = '%'.mb_strtolower($search).'%';
            $query->where(function ($searchQuery) use ($term) {
                $searchQuery->whereRaw('LOWER(name_id) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(name_en) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(subtitle_id) LIKE ?', [$term]);
            });
        }

        $categories = $query->orderBy('categories_id', 'asc')
            ->paginate(8)
            ->withQueryString();

        $totalCategoriesCount = Category::count();
        $totalRelationsCount = DB::table('place_category')->count();

        // After a failed save the popup reopens on the category being edited.
        $editId = $request->old('_category_id') ?: $editId;
        $editCategory = $editId
            ? Category::withCount('places')
                ->with(['places' => fn ($places) => $places->select('places.places_id', 'places.name')->orderBy('places.name')->limit(3)])
                ->find($editId)
            : null;

        return view('admin.categories.index', [
            'categories' => $categories,
            'search' => $search,
            'totalCategoriesCount' => $totalCategoriesCount,
            'totalRelationsCount' => $totalRelationsCount,
            'editCategory' => $editCategory,
        ]);
    }

    public function create()
    {
        return redirect()->route('admin.categories.index');
    }

    public function store(Request $request)
    {
        $data = $request->validate($this->rules(Rule::unique('categories', 'slug')->whereNull('deleted_at')));

        $slug = ! empty($data['slug']) ? $data['slug'] : Str::slug($data['name_id']);

        // A slug made from the name is not covered by the rule above; without
        // this check a second "Pantai" fails on the unique index (HTTP 500).
        if (empty($data['slug']) && Category::where('slug', $slug)->exists()) {
            throw ValidationException::withMessages([
                'name_id' => "Kategori dengan nama ini sudah ada (slug \"{$slug}\").",
            ]);
        }

        $category = Category::create([
            'name_id' => $data['name_id'],
            'subtitle_id' => $data['subtitle_id'] ?? null,
            'name_en' => $data['name_en'],
            'icon_symbol' => $data['icon_symbol'] ?? Category::DEFAULT_ICON_SYMBOL,
            'show_in_onboarding' => $data['show_in_onboarding'] ?? true,
            'slug' => $slug,
        ]);

        return redirect()->route('admin.categories.index')
            ->with('category_created_success', "\"{$category->name_id}\" berhasil ditambahkan.");
    }

    public function edit(Category $category)
    {
        return redirect()->route('admin.categories.index', ['edit_id' => $category->categories_id]);
    }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate($this->rules(
            Rule::unique('categories', 'slug')->whereNull('deleted_at')->ignore($category->categories_id, 'categories_id')
        ));

        $updateData = [
            'name_id' => $data['name_id'],
            'name_en' => $data['name_en'],
        ];

        // Only fields the request sends are changed: a field emptied in the
        // popup arrives as null and is cleared, while a request that leaves a
        // field out keeps the stored value.
        foreach (['subtitle_id', 'icon_symbol', 'show_in_onboarding'] as $field) {
            if ($request->exists($field)) {
                $updateData[$field] = $data[$field];
            }
        }

        // These two always need a value.
        if (array_key_exists('icon_symbol', $updateData)) {
            $updateData['icon_symbol'] ??= Category::DEFAULT_ICON_SYMBOL;
        }
        if (array_key_exists('show_in_onboarding', $updateData)) {
            $updateData['show_in_onboarding'] ??= true;
        }

        if (! empty($data['slug'])) {
            $updateData['slug'] = $data['slug'];
        }

        $category->update($updateData);

        return redirect()->route('admin.categories.index')
            ->with('status', "\"{$category->name_id}\" berhasil diperbarui.");
    }

    private function rules($uniqueSlug): array
    {
        return [
            'name_id' => ['required', 'string', 'max:255'],
            'subtitle_id' => ['nullable', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'icon_symbol' => ['nullable', 'string', Rule::in(array_keys(Category::ICON_SYMBOLS))],
            'show_in_onboarding' => ['nullable', 'boolean'],
            'slug' => ['nullable', 'string', 'max:255', $uniqueSlug],
        ];
    }

    public function destroy(Category $category)
    {
        // FK ON DELETE RESTRICT hanya menolak hard delete; soft delete adalah
        // UPDATE, jadi pemakaian harus dicek di sini (PRD audit 2026-10-10).
        $inUse = $category->places()->withTrashed()->exists()
            || $category->trips()->withTrashed()->exists()
            || DB::table('user_default_interest_category')->where('categories_id', $category->categories_id)->exists();

        if ($inUse) {
            return redirect()->route('admin.categories.index')
                ->with('error', "\"{$category->name_id}\" masih dipakai tempat, trip, atau preferensi user, tidak bisa dihapus.");
        }

        $name = $category->name_id;
        $category->delete();

        return redirect()->route('admin.categories.index')
            ->with('status', "\"{$name}\" berhasil dihapus.");
    }

    public function activities(Category $category)
    {
        $activities = $category->activitiesAsSubject()
            ->with('causer')
            ->latest()
            ->take(30)
            ->get();

        return response()->json([
            'subject' => $category->name_id,
            'type' => 'Kategori Destinasi',
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
