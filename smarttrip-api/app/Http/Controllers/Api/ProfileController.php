<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Itinerary\Topsis;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Knuckles\Scribe\Attributes\Endpoint;
use Knuckles\Scribe\Attributes\Group;

/**
 * F009 - preferensi default akun (docs/prd design spec Section 12):
 * user_default_interest_category + 4 kolom default_weight_* di users.
 * Sumber pre-fill trip baru (Section 7 langkah 3) - trip yang sudah
 * digenerate tetap pakai snapshot bobotnya sendiri, tidak ikut berubah
 * kalau default di profil diedit belakangan.
 */
#[Group('Profil', 'Data akun dan preferensi default untuk trip baru.')]
class ProfileController extends Controller
{
    #[Endpoint('Lihat preferensi', 'Minat dan bobot kriteria default untuk trip baru.')]
    public function show(Request $request)
    {
        $user = $request->user()->load('defaultInterestCategories');

        return response()->json($this->present($user));
    }

    #[Endpoint('Simpan preferensi', 'Rating 0-10 per kriteria dinormalkan jadi bobot dengan total 1; semua 0 berarti bobot sama rata.')]
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

        $weights = collect(Topsis::normalizeWeights([
            'kategori' => $data['rating_kategori'], 'jarak' => $data['rating_jarak'],
            'anggaran' => $data['rating_anggaran'], 'rating' => $data['rating_rating'],
        ]))
            ->mapWithKeys(fn ($weight, $criterion) => ["default_weight_{$criterion}" => $weight])->all();

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
