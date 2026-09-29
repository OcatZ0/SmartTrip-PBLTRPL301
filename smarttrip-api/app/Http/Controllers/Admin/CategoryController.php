<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

/**
 * F022 (docs/prd design spec Section 14) - CRUD categories: list/tambah/
 * edit/hapus tag kategori, jaga slug unik biar tidak ada duplikat mirip
 * ("kuliner" vs "wisata kuliner"). Riwayat perubahan (F023) sama seperti
 * Place - dilog lewat LogsActivity di model.
 */
class CategoryController extends Controller
{
    public function index()
    {
        return view('admin.categories.index', [
            'categories' => Category::orderBy('name_id')->paginate(25),
        ]);
    }

    public function create()
    {
        return view('admin.categories.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'name_id' => ['required', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'slug' => [
                'nullable', 'string', 'max:255',
                Rule::unique('categories', 'slug')->whereNull('deleted_at'),
            ],
        ]);

        $category = Category::create([
            'name_id' => $data['name_id'],
            'name_en' => $data['name_en'],
            'slug' => ! empty($data['slug']) ? $data['slug'] : Str::slug($data['name_id']),
        ]);

        return redirect()->route('admin.categories.index')->with('status', "\"{$category->name_id}\" ditambahkan.");
    }

    public function edit(Category $category)
    {
        return view('admin.categories.edit', [
            'category' => $category,
            'activities' => $category->activitiesAsSubject()->with('causer')->latest()->get(),
        ]);
    }

    public function update(Request $request, Category $category)
    {
        $data = $request->validate([
            'name_id' => ['required', 'string', 'max:255'],
            'name_en' => ['required', 'string', 'max:255'],
            'slug' => [
                'required', 'string', 'max:255',
                Rule::unique('categories', 'slug')->whereNull('deleted_at')->ignore($category->categories_id, 'categories_id'),
            ],
        ]);

        $category->update($data);

        return redirect()->route('admin.categories.index')->with('status', "\"{$category->name_id}\" diperbarui.");
    }

    public function destroy(Category $category)
    {
        $category->delete();

        return redirect()->route('admin.categories.index')->with('status', "\"{$category->name_id}\" dihapus.");
    }
}
