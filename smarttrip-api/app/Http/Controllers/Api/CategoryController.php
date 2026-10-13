<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;

/**
 * Daftar kategori minat untuk chip "Pilih Minat" di mobile (onboarding A4,
 * trip setup C3, Profil F1). Publik seperti katalog tempat - taksonomi ini
 * bukan data milik user.
 */
class CategoryController extends Controller
{
    public function index()
    {
        $categories = Category::query()
            ->orderBy('name_id')
            ->get(['categories_id', 'name_id', 'name_en', 'slug']);

        return response()->json(['data' => $categories]);
    }
}
