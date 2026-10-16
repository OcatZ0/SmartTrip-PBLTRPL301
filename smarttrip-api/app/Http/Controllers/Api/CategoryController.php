<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use Illuminate\Http\Request;

/**
 * Daftar kategori minat untuk chip "Pilih Minat" di mobile (onboarding A4,
 * trip setup C3, Profil F1). Publik seperti katalog tempat - taksonomi ini
 * bukan data milik user.
 *
 * ?onboarding=1 hanya mengembalikan kategori yang admin tandai tampil di
 * onboarding A4; tanpa parameter (C3, F1) semua kategori dikembalikan.
 */
class CategoryController extends Controller
{
    public function index(Request $request)
    {
        $categories = Category::query()
            ->when($request->boolean('onboarding'), fn ($query) => $query->where('show_in_onboarding', true))
            ->orderBy('name_id')
            ->get(['categories_id', 'name_id', 'name_en', 'slug', 'icon_symbol', 'show_in_onboarding'])
            // icon_symbol as the admin list shows it (the stored icon, or one
            // guessed from the name while it is still the default); the app
            // draws it with the same Bootstrap Icons glyph.
            ->map(fn (Category $category) => [
                'categories_id' => $category->categories_id,
                'name_id' => $category->name_id,
                'name_en' => $category->name_en,
                'slug' => $category->slug,
                'icon_symbol' => $category->iconMeta()['key'],
                'show_in_onboarding' => $category->show_in_onboarding,
            ]);

        return response()->json(['data' => $categories]);
    }
}
