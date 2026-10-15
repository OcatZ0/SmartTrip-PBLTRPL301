<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * F021 - Admin dapat mengelola kategori tempat wisata (CRUD categories lewat Modal UI)
 */
class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $search = $request->string('search')->trim()->toString();
        $editId = $request->integer('edit_id');

        $query = Category::query()->withCount('places');

        if (! empty($search)) {
            $term = '%'.mb_strtolower($search).'%';
            $query->where(function ($searchQuery) use ($term) {
                $searchQuery->whereRaw('LOWER(name_id) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(name_en) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(subtitle_id) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(ai_keywords) LIKE ?', [$term]);
            });
        }

        $categories = $query->orderBy('categories_id', 'asc')
            ->paginate(8)
            ->withQueryString();

        $totalCategoriesCount = Category::count();
        $totalRelationsCount = DB::table('place_category')->count();

        $editCategory = $editId ? Category::withCount('places')->find($editId) : null;

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
        $data = $request->validate([
            'name_id' => ['required', 'string', 'max:255'],
            'subtitle_id' => ['nullable', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'icon_symbol' => ['nullable', 'string', 'max:100'],
            'ai_keywords' => ['nullable', 'string'],
            'visibility_onboarding' => ['nullable', 'string', 'max:100'],
            'slug' => [
                'nullable', 'string', 'max:255',
                Rule::unique('categories', 'slug')->whereNull('deleted_at'),
            ],
        ]);

        $category = Category::create([
            'name_id' => $data['name_id'],
            'subtitle_id' => $data['subtitle_id'] ?? null,
            'name_en' => $data['name_en'],
            'icon_symbol' => $data['icon_symbol'] ?? 'ombak',
            'ai_keywords' => $data['ai_keywords'] ?? null,
            'visibility_onboarding' => $data['visibility_onboarding'] ?? 'Tampil di A4',
            'slug' => ! empty($data['slug']) ? $data['slug'] : Str::slug($data['name_id']),
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
        $data = $request->validate([
            'name_id' => ['required', 'string', 'max:255'],
            'subtitle_id' => ['nullable', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'icon_symbol' => ['nullable', 'string', 'max:100'],
            'ai_keywords' => ['nullable', 'string'],
            'visibility_onboarding' => ['nullable', 'string', 'max:100'],
            'slug' => [
                'nullable', 'string', 'max:255',
                Rule::unique('categories', 'slug')->whereNull('deleted_at')->ignore($category->categories_id, 'categories_id'),
            ],
        ]);

        $updateData = [
            'name_id' => $data['name_id'],
            'subtitle_id' => $data['subtitle_id'] ?? $category->subtitle_id,
            'name_en' => $data['name_en'],
            'icon_symbol' => $data['icon_symbol'] ?? $category->icon_symbol,
            'ai_keywords' => $data['ai_keywords'] ?? $category->ai_keywords,
            'visibility_onboarding' => $data['visibility_onboarding'] ?? $category->visibility_onboarding,
        ];

        if (! empty($data['slug'])) {
            $updateData['slug'] = $data['slug'];
        }

        $category->update($updateData);

        return redirect()->route('admin.categories.index')
            ->with('status', "\"{$category->name_id}\" berhasil diperbarui.");
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
