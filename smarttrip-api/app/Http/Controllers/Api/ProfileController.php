<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

/**
 * F009 - preferensi default akun (docs/prd design spec Section 12):
 * user_default_interest_category + 4 kolom default_weight_* di users.
 * Sumber pre-fill trip baru (Section 7 langkah 3) - trip yang sudah
 * digenerate tetap pakai snapshot bobotnya sendiri, tidak ikut berubah
 * kalau default di profil diedit belakangan.
 */
class ProfileController extends Controller
{
    public function show(Request $request)
    {
        $user = $request->user()->load('defaultInterestCategories');

        return response()->json($this->present($user));
    }

    public function update(Request $request)
    {
        $data = $request->validate([
            'category_ids' => ['required', 'array', 'min:1'],
            'category_ids.*' => ['integer', Rule::exists('categories', 'categories_id')->whereNull('deleted_at')],
            'rating_kategori' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_jarak' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_anggaran' => ['required', 'numeric', 'min:0', 'max:10'],
            'rating_rating' => ['required', 'numeric', 'min:0', 'max:10'],
        ]);

        $sum = $data['rating_kategori'] + $data['rating_jarak'] + $data['rating_anggaran'] + $data['rating_rating'];

        $weights = $sum > 0 ? [
            'default_weight_kategori' => $data['rating_kategori'] / $sum,
            'default_weight_jarak' => $data['rating_jarak'] / $sum,
            'default_weight_anggaran' => $data['rating_anggaran'] / $sum,
            'default_weight_rating' => $data['rating_rating'] / $sum,
        ] : [
            'default_weight_kategori' => 0.25, 'default_weight_jarak' => 0.25,
            'default_weight_anggaran' => 0.25, 'default_weight_rating' => 0.25,
        ];

        $user = $request->user();

        DB::transaction(function () use ($user, $data, $weights) {
            $user->defaultInterestCategories()->sync($data['category_ids']);
            $user->update($weights);
        });

        return response()->json($this->present($user->fresh('defaultInterestCategories')));
    }

    private function present($user): array
    {
        return [
            'categories' => $user->defaultInterestCategories->map(fn ($category) => [
                'categories_id' => $category->categories_id,
                'name_id' => $category->name_id,
                'name_en' => $category->name_en,
                'slug' => $category->slug,
            ])->values(),
            'default_weight_kategori' => $user->default_weight_kategori !== null ? (float) $user->default_weight_kategori : null,
            'default_weight_jarak' => $user->default_weight_jarak !== null ? (float) $user->default_weight_jarak : null,
            'default_weight_anggaran' => $user->default_weight_anggaran !== null ? (float) $user->default_weight_anggaran : null,
            'default_weight_rating' => $user->default_weight_rating !== null ? (float) $user->default_weight_rating : null,
        ];
    }
}
