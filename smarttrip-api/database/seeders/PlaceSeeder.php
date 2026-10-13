<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Place;
use Illuminate\Database\Seeder;

/**
 * Starter catalog for local development.
 *
 * Names and coordinates are real, taken from OpenStreetMap on 2026-10-13
 * (Overpass API, data (c) OpenStreetMap contributors, ODbL); the OSM element
 * is noted per row. Categories, visit minutes, is_outdoor and kecamatan are
 * starting estimates that Gemini/admin would normally fill, and stay editable
 * in the admin panel. Rating and estimated_cost_idr are left empty on
 * purpose: OSM has no such data and the backend already falls back
 * (PlaceRatingEstimator, PlaceCostEstimator).
 */
class PlaceSeeder extends Seeder
{
    private const PLACES = [
        // Attractions
        ['osm' => 'w608905683', 'name' => 'Jembatan Barelang (Raja Haji Fisabilillah)', 'type' => 'attraction', 'lat' => 0.98154, 'lng' => 104.04160, 'address' => 'Jembatan Barelang 1, Batam', 'kecamatan' => null, 'minutes' => 60, 'outdoor' => true, 'categories' => ['landmark', 'spot-foto']],
        ['osm' => 'n5526812884', 'name' => 'Monumen Welcome to Batam', 'type' => 'attraction', 'lat' => 1.12216, 'lng' => 104.05434, 'address' => 'Bukit Clara, Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 30, 'outdoor' => true, 'categories' => ['landmark', 'spot-foto']],
        ['osm' => 'n1324450032', 'name' => 'Masjid Agung Batam', 'type' => 'attraction', 'lat' => 1.12640, 'lng' => 104.05338, 'address' => 'Jl. Engku Puteri, Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 45, 'outdoor' => false, 'categories' => ['religi', 'sejarah']],
        ['osm' => 'r8244900', 'name' => 'Dataran Engku Putri', 'type' => 'attraction', 'lat' => 1.12864, 'lng' => 104.05406, 'address' => 'Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 45, 'outdoor' => true, 'categories' => ['rekreasi']],
        ['osm' => 'n6865933721', 'name' => 'Maha Vihara Duta Maitreya', 'type' => 'attraction', 'lat' => 1.12944, 'lng' => 104.03472, 'address' => 'Sei Panas, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 60, 'outdoor' => false, 'categories' => ['religi', 'sejarah']],
        ['osm' => 'w576152031', 'name' => 'Museum Raja Ali Haji', 'type' => 'attraction', 'lat' => 1.12939, 'lng' => 104.05377, 'address' => 'Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 60, 'outdoor' => false, 'categories' => ['sejarah']],
        ['osm' => 'n703856231', 'name' => 'Pantai Ocarina', 'type' => 'attraction', 'lat' => 1.15196, 'lng' => 104.05471, 'address' => 'Sadai, Bengkong, Batam', 'kecamatan' => 'Bengkong', 'minutes' => 120, 'outdoor' => true, 'categories' => ['pantai', 'rekreasi']],
        ['osm' => 'w482249158', 'name' => 'Pantai Nongsa', 'type' => 'attraction', 'lat' => 1.19468, 'lng' => 104.08896, 'address' => 'Nongsa, Batam', 'kecamatan' => 'Nongsa', 'minutes' => 120, 'outdoor' => true, 'categories' => ['pantai', 'alam']],
        ['osm' => 'n702364161', 'name' => 'Pantai Setokok', 'type' => 'attraction', 'lat' => 0.92335, 'lng' => 104.06094, 'address' => 'Pulau Setokok, Batam', 'kecamatan' => null, 'minutes' => 120, 'outdoor' => true, 'categories' => ['pantai', 'alam']],
        ['osm' => 'w1180364714', 'name' => 'Infinite Studio Kota Tua', 'type' => 'attraction', 'lat' => 1.18677, 'lng' => 104.09755, 'address' => 'Nongsa, Batam', 'kecamatan' => 'Nongsa', 'minutes' => 90, 'outdoor' => true, 'categories' => ['spot-foto', 'rekreasi']],
        ['osm' => 'n11936563718', 'name' => 'Tangga 1000 Taman Habibie', 'type' => 'attraction', 'lat' => 1.14504, 'lng' => 103.94751, 'address' => 'Sekupang, Batam', 'kecamatan' => 'Sekupang', 'minutes' => 60, 'outdoor' => true, 'categories' => ['alam', 'spot-foto']],
        ['osm' => 'w767432460', 'name' => 'Monumen Perahu Eks Pengungsi Vietnam', 'type' => 'attraction', 'lat' => 0.75369, 'lng' => 104.20348, 'address' => 'Kampung Vietnam, Pulau Galang, Batam', 'kecamatan' => 'Galang', 'minutes' => 120, 'outdoor' => true, 'categories' => ['sejarah']],
        ['osm' => 'w1341679571', 'name' => 'Masjid Sultan Mahmud Riayat Syah', 'type' => 'attraction', 'lat' => 1.05113, 'lng' => 103.93511, 'address' => 'Tanjung Uncang, Batam', 'kecamatan' => 'Batu Aji', 'minutes' => 45, 'outdoor' => false, 'categories' => ['religi']],
        ['osm' => 'w59398752', 'name' => 'Nagoya Hill Shopping Centre', 'type' => 'attraction', 'lat' => 1.14627, 'lng' => 104.01261, 'address' => 'Nagoya, Lubuk Baja, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => 120, 'outdoor' => false, 'categories' => ['belanja']],
        ['osm' => 'w606276855', 'name' => 'Mega Mall Batam Centre', 'type' => 'attraction', 'lat' => 1.12924, 'lng' => 104.05598, 'address' => 'Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 120, 'outdoor' => false, 'categories' => ['belanja']],

        // Culinary
        ['osm' => 'n903121912', 'name' => 'Golden Prawn Seafood', 'type' => 'culinary', 'lat' => 1.16030, 'lng' => 104.03718, 'address' => 'Bengkong Laut, Batam', 'kecamatan' => 'Bengkong', 'minutes' => 90, 'outdoor' => false, 'categories' => ['kuliner-seafood']],
        ['osm' => 'n703813205', 'name' => 'Wey Wey Seafood', 'type' => 'culinary', 'lat' => 1.15253, 'lng' => 103.99804, 'address' => 'Batu Ampar, Batam', 'kecamatan' => 'Batu Ampar', 'minutes' => 90, 'outdoor' => false, 'categories' => ['kuliner-seafood']],
        ['osm' => 'n4100880791', 'name' => 'Setia Budi Seafood Restaurant', 'type' => 'culinary', 'lat' => 1.19538, 'lng' => 104.08562, 'address' => 'Jl. Hang Lekiu, Nongsa, Batam', 'kecamatan' => 'Nongsa', 'minutes' => 90, 'outdoor' => false, 'categories' => ['kuliner-seafood']],
        ['osm' => 'w1053869549', 'name' => 'Ocean Garden Seafood', 'type' => 'culinary', 'lat' => 1.13439, 'lng' => 104.04797, 'address' => 'Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => 90, 'outdoor' => false, 'categories' => ['kuliner-seafood']],
        ['osm' => 'n4476868093', 'name' => 'Kedai Kopi Pelangi (Sup Ikan)', 'type' => 'culinary', 'lat' => 1.13274, 'lng' => 104.01116, 'address' => 'Lubuk Baja, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => 45, 'outdoor' => false, 'categories' => ['kuliner-lokal', 'kuliner-seafood']],
        ['osm' => 'n5791489156', 'name' => 'Old Place Frog Porridge', 'type' => 'culinary', 'lat' => 1.14301, 'lng' => 104.01179, 'address' => 'Jalan Imam Bonjol, Nagoya, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => 45, 'outdoor' => false, 'categories' => ['kuliner-lokal']],
        ['osm' => 'n5791489154', 'name' => 'Bubur Johor', 'type' => 'culinary', 'lat' => 1.14302, 'lng' => 104.01214, 'address' => 'Jalan Imam Bonjol, Nagoya, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => 45, 'outdoor' => false, 'categories' => ['kuliner-lokal']],
        ['osm' => 'w1054953244', 'name' => 'Cin Hui Ayam Cabe Hijau Selat Panjang', 'type' => 'culinary', 'lat' => 1.12968, 'lng' => 104.01194, 'address' => 'Jl. Bunga Raya, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => 45, 'outdoor' => false, 'categories' => ['kuliner-lokal']],
        ['osm' => 'n6592791285', 'name' => 'Maroenk (Soto Kwali Penuin)', 'type' => 'culinary', 'lat' => 1.13525, 'lng' => 104.00615, 'address' => 'Gate 2 Grand Batam Mall, Penuin, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => 45, 'outdoor' => false, 'categories' => ['kuliner-lokal']],

        // Lodging (C4 hotel recommendations and search)
        ['osm' => 'n11602267672', 'name' => 'Batam Marriott Hotel Harbour Bay', 'type' => 'lodging', 'lat' => 1.15415, 'lng' => 103.99674, 'address' => 'Harbour Bay, Batu Ampar, Batam', 'kecamatan' => 'Batu Ampar', 'minutes' => null, 'outdoor' => false, 'categories' => []],
        ['osm' => 'n4596262794', 'name' => 'Swiss-Belhotel Harbour Bay', 'type' => 'lodging', 'lat' => 1.15365, 'lng' => 104.00042, 'address' => 'Harbour Bay, Batu Ampar, Batam', 'kecamatan' => 'Batu Ampar', 'minutes' => null, 'outdoor' => false, 'categories' => []],
        ['osm' => 'n5526812905', 'name' => 'Harris Hotel Batam Center', 'type' => 'lodging', 'lat' => 1.13051, 'lng' => 104.05403, 'address' => 'Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => null, 'outdoor' => false, 'categories' => []],
        ['osm' => 'w254319212', 'name' => 'Montigo Resorts Nongsa', 'type' => 'lodging', 'lat' => 1.18168, 'lng' => 104.07266, 'address' => 'Nongsa, Batam', 'kecamatan' => 'Nongsa', 'minutes' => null, 'outdoor' => false, 'categories' => []],
        ['osm' => 'w575205306', 'name' => 'Radisson Golf & Convention Center Batam', 'type' => 'lodging', 'lat' => 1.10355, 'lng' => 104.03180, 'address' => 'Jalan Jendral Sudirman, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => null, 'outdoor' => false, 'categories' => []],
        ['osm' => 'w1055245361', 'name' => 'Amaris Hotel Nagoya Hill Batam', 'type' => 'lodging', 'lat' => 1.14542, 'lng' => 104.01362, 'address' => 'Nagoya, Lubuk Baja, Batam', 'kecamatan' => 'Lubuk Baja', 'minutes' => null, 'outdoor' => false, 'categories' => []],
        ['osm' => 'w1013975659', 'name' => 'Mercure Batam', 'type' => 'lodging', 'lat' => 1.13440, 'lng' => 104.04473, 'address' => 'Batam Centre, Batam', 'kecamatan' => 'Batam Kota', 'minutes' => null, 'outdoor' => false, 'categories' => []],
    ];

    public function run(): void
    {
        $this->call(CategorySeeder::class);
        $categoryIds = Category::query()->pluck('categories_id', 'slug');

        foreach (self::PLACES as $row) {
            $place = Place::firstOrCreate(
                ['name' => $row['name'], 'type' => $row['type']],
                [
                    'lat' => $row['lat'],
                    'lng' => $row['lng'],
                    'address' => $row['address'],
                    'kecamatan' => $row['kecamatan'],
                    'source' => 'manual',
                    'estimated_visit_minutes' => $row['minutes'],
                    'is_outdoor' => $row['outdoor'],
                    'category_tags_reviewed' => $row['categories'] !== [],
                    'types' => ['osm:'.$row['osm']],
                    'external_place_id' => 'osm:'.$row['osm'],
                ]
            );

            // Rows seeded before the id was filled in get it here, so
            // Discovery skips them by id, not only by name and distance.
            if ($place->external_place_id === null) {
                $place->update(['external_place_id' => 'osm:'.$row['osm']]);
            }

            $place->categories()->syncWithoutDetaching(
                collect($row['categories'])->map(fn ($slug) => $categoryIds[$slug])->all()
            );
        }
    }
}
