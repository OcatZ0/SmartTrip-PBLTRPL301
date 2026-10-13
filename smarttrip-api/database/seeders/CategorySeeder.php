<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

/**
 * Initial interest taxonomy. docs/prd US11: categories must exist before the
 * first Discovery/Enrichment run, because Gemini may only pick existing tags.
 */
class CategorySeeder extends Seeder
{
    public const CATEGORIES = [
        'pantai' => ['Pantai', 'Beach'],
        'alam' => ['Wisata Alam', 'Nature'],
        'sejarah' => ['Sejarah & Budaya', 'History & Culture'],
        'religi' => ['Wisata Religi', 'Religious Sites'],
        'landmark' => ['Landmark & Ikon Kota', 'Landmarks'],
        'spot-foto' => ['Spot Foto', 'Photo Spots'],
        'rekreasi' => ['Taman & Rekreasi', 'Parks & Recreation'],
        'belanja' => ['Belanja', 'Shopping'],
        'kuliner-seafood' => ['Kuliner Seafood', 'Seafood'],
        'kuliner-lokal' => ['Kuliner Lokal', 'Local Food'],
    ];

    public function run(): void
    {
        foreach (self::CATEGORIES as $slug => [$nameId, $nameEn]) {
            Category::firstOrCreate(['slug' => $slug], ['name_id' => $nameId, 'name_en' => $nameEn]);
        }
    }
}
