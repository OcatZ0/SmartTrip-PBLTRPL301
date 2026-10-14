<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Place;
use App\Models\PlaceCandidate;
use Illuminate\Database\Seeder;

class PlaceSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Categories (8 Master Categories from Figma UI)
        $catBahari = Category::updateOrCreate(['slug' => 'wisata-bahari'], [
            'name_id' => 'Wisata Bahari',
            'subtitle_id' => 'Prioritas Utama Pulau',
            'name_en' => 'Marine Tourism',
            'icon_symbol' => 'ombak',
            'ai_keywords' => 'Pulau, terumbu karang, kapal pompong, snorkeling, diving',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catPantai = Category::updateOrCreate(['slug' => 'pantai-senja'], [
            'name_id' => 'Pantai & Senja',
            'subtitle_id' => 'Sunset spot & pesisir',
            'name_en' => 'Beach & Sunset',
            'icon_symbol' => 'senja',
            'ai_keywords' => 'Sunset, pasir putih, laut, resor, gazebo',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catSeafood = Category::updateOrCreate(['slug' => 'kuliner-seafood'], [
            'name_id' => 'Kuliner Seafood',
            'subtitle_id' => 'Kelong & restoran pesisir',
            'name_en' => 'Seafood Culinary',
            'icon_symbol' => 'kuliner',
            'ai_keywords' => 'Gonggong, kepiting, kelong, ikan bakar, udang',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catBelanja = Category::updateOrCreate(['slug' => 'belanja-mall'], [
            'name_id' => 'Belanja & Mall',
            'subtitle_id' => 'Pusat oleh-oleh & duty free',
            'name_en' => 'Shopping & Malls',
            'icon_symbol' => 'belanja',
            'ai_keywords' => 'Mall, duty free, fashion, suvenir, parfum',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catBudaya = Category::updateOrCreate(['slug' => 'budaya-sejarah'], [
            'name_id' => 'Budaya & Sejarah',
            'subtitle_id' => 'Situs Melayu & cagar budaya',
            'name_en' => 'Culture & Heritage',
            'icon_symbol' => 'budaya',
            'ai_keywords' => 'Sejarah, cagar budaya, vihara, masjid, museum',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catKeluarga = Category::updateOrCreate(['slug' => 'wisata-keluarga'], [
            'name_id' => 'Wisata Keluarga',
            'subtitle_id' => 'Taman hiburan & atraksi',
            'name_en' => 'Family Attractions',
            'icon_symbol' => 'keluarga',
            'ai_keywords' => 'Taman hiburan, permainan, kolam renang, wahana',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catMalam = Category::updateOrCreate(['slug' => 'malam-kafe'], [
            'name_id' => 'Malam & Kafe',
            'subtitle_id' => 'Kopi artisan & live lounge',
            'name_en' => 'Nightlife & Cafes',
            'icon_symbol' => 'malam',
            'ai_keywords' => 'Kopi artisan, live music, bar, kafe, nongkrong',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        $catSpa = Category::updateOrCreate(['slug' => 'spa-relaksasi'], [
            'name_id' => 'Spa & Relaksasi',
            'subtitle_id' => 'Pijat tradisional & wellness',
            'name_en' => 'Spa & Wellness',
            'icon_symbol' => 'spa',
            'ai_keywords' => 'Spa, pijat tradisional, wellness, aromaterapi',
            'visibility_onboarding' => 'Tampil di A4',
        ]);

        // 2. Places from Figma UI
        $places = [
            [
                'google_place_id' => 'BTM-DST-001',
                'name' => 'Jembatan Barelang I',
                'type' => 'attraction',
                'lat' => 0.9852780,
                'lng' => 104.0416670,
                'address' => 'Jl. Trans Barelang, Sagulung, Kota Batam',
                'kecamatan' => 'Sagulung',
                'rating' => 4.80,
                'review_count' => 1200,
                'photo_url' => 'https://images.unsplash.com/photo-1518495973542-4542c06a5843?w=300&h=300&fit=crop',
                'description' => 'Jembatan ikonik kebanggaan Batam yang menghubungkan Pulau Batam dengan pulau-pulau di sekitarnya.',
                'estimated_cost_idr' => 0,
                'estimated_visit_minutes' => 60,
                'is_outdoor' => true,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catBudaya,
                'ticket_label' => 'Gratis / Parkir Rp 10.000',
            ],
            [
                'google_place_id' => 'BTM-DST-014',
                'name' => 'Pantai Viovio Barelang',
                'type' => 'attraction',
                'lat' => 0.8654210,
                'lng' => 104.2145890,
                'address' => 'Jl. Trans Barelang Jembatan 5, Sijantung, Kec. Galang, Kota Batam',
                'kecamatan' => 'Galang',
                'rating' => 4.60,
                'review_count' => 850,
                'photo_url' => 'https://cdn-jpr.jawapos.com/images/41/2024/07/08/Bukit-Welcome-to-Batam-Opang-Sopanji-Shutterstock-1255382649.png',
                'description' => 'Destinasi pantai dengan pemandangan sunset memukau, glamping resort, dan wahana foto instagramable.',
                'estimated_cost_idr' => 15000,
                'estimated_visit_minutes' => 90,
                'is_outdoor' => true,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catPantai,
                'ticket_label' => 'Rp 15.000',
            ],
            [
                'google_place_id' => 'BTM-DST-022',
                'name' => 'Golden Prawn 933 Seafood',
                'type' => 'culinary',
                'lat' => 1.1523400,
                'lng' => 104.0623400,
                'address' => 'Bengkong Laut, Kec. Bengkong, Kota Batam',
                'kecamatan' => 'Bengkong',
                'rating' => 4.70,
                'review_count' => 2100,
                'photo_url' => 'https://media-cdn.tripadvisor.com/media/photo-s/04/1b/1a/4d/golden-prawn-933.jpg',
                'description' => 'Restoran seafood segar terapung di Bengkong Laut dengan beragam olahan gonggong, kepiting, dan ikan.',
                'estimated_cost_idr' => 150000,
                'estimated_visit_minutes' => 90,
                'is_outdoor' => false,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catSeafood,
                'ticket_label' => 'Kisaran Rp 150rb',
            ],
            [
                'google_place_id' => 'BTM-DST-045',
                'name' => 'Warung Mak Kote Piayu',
                'type' => 'culinary',
                'lat' => 1.0421500,
                'lng' => 104.0892000,
                'address' => 'Tanjung Piayu Laut, Kec. Sekupang, Kota Batam',
                'kecamatan' => 'Sekupang',
                'rating' => 4.50,
                'review_count' => 310,
                'photo_url' => 'https://images.unsplash.com/photo-1544025162-d76694265947?w=300&h=300&fit=crop',
                'description' => 'Warung kuliner tradisional khas Melayu Batam di kawasan pesisir Piayu Laut.',
                'estimated_cost_idr' => null,
                'estimated_visit_minutes' => 60,
                'is_outdoor' => true,
                'category_tags_reviewed' => false,
                'source' => 'manual',
                'category' => $catSeafood,
                'ticket_label' => 'Belum Diatur',
            ],
            [
                'google_place_id' => 'BTM-DST-058',
                'name' => 'Snorkeling Pulau Abang',
                'type' => 'attraction',
                'lat' => 0.5732100,
                'lng' => 104.1984200,
                'address' => 'Pulau Abang, Kec. Galang Selatan, Kota Batam',
                'kecamatan' => 'Galang Selatan',
                'rating' => 4.90,
                'review_count' => 420,
                'photo_url' => 'https://cms.kepriprov.go.id/api/files/uploads/2026/04/f9bd7540-9a2e-4a0b-bbed-4ebeb95ed0e6.jpg',
                'description' => 'Spot snorkeling konservasi terumbu karang indah "Blue Coral" khas Pulau Abang Batam.',
                'estimated_cost_idr' => 350000,
                'estimated_visit_minutes' => 240,
                'is_outdoor' => true,
                'category_tags_reviewed' => false,
                'source' => 'manual',
                'category' => $catBahari,
                'ticket_label' => 'Belum Ada Jadwal Kapal',
            ],
            [
                'google_place_id' => 'BTM-DST-008',
                'name' => 'Nagoya Hill Shopping Mall',
                'type' => 'attraction',
                'lat' => 1.1448200,
                'lng' => 104.0145800,
                'address' => 'Jl. Teuku Umar, Lubuk Baja, Kota Batam',
                'kecamatan' => 'Lubuk Baja',
                'rating' => 4.50,
                'review_count' => 4500,
                'photo_url' => 'https://upload.wikimedia.org/wikipedia/commons/6/6b/Pintu_Timur_Nagoya_Hill.jpg',
                'description' => 'Pusat perbelanjaan terbesar dan teramai di Batam dengan berbagai tenant hiburan, kuliner, dan belanja.',
                'estimated_cost_idr' => 0,
                'estimated_visit_minutes' => 120,
                'is_outdoor' => false,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catBelanja,
                'ticket_label' => 'Bebas Masuk',
            ],
            [
                'google_place_id' => 'BTM-DST-009',
                'name' => 'Pantai Dendang Melayu',
                'type' => 'attraction',
                'lat' => 0.9812000,
                'lng' => 104.0435000,
                'address' => 'Sebelum Jembatan I Barelang, Tembesi, Sagulung, Kota Batam',
                'kecamatan' => 'Sagulung',
                'rating' => 4.40,
                'review_count' => 540,
                'photo_url' => 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&h=300&fit=crop',
                'description' => 'Spot bersantai ikonik sebelum melintasi Jembatan Barelang dengan pemandangan laut lepas.',
                'estimated_cost_idr' => 10000,
                'estimated_visit_minutes' => 45,
                'is_outdoor' => true,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catPantai,
                'ticket_label' => 'Rp 10.000',
            ],
            [
                'google_place_id' => 'BTM-DST-010',
                'name' => 'Alun-Alun Engku Putri',
                'type' => 'attraction',
                'lat' => 1.1312000,
                'lng' => 104.0528000,
                'address' => 'Teluk Tering, Batam Kota, Kota Batam',
                'kecamatan' => 'Batam Kota',
                'rating' => 4.70,
                'review_count' => 1800,
                'photo_url' => 'https://images.unsplash.com/photo-1477959858617-67f30ac4ce6d?w=300&h=300&fit=crop',
                'description' => 'Alun-alun terbuka hijau di pusat pemerintahan Kota Batam.',
                'estimated_cost_idr' => 0,
                'estimated_visit_minutes' => 60,
                'is_outdoor' => true,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catBudaya,
                'ticket_label' => 'Gratis',
            ],
            [
                'google_place_id' => 'BTM-DST-011',
                'name' => 'Resto Harbour Bay Seafood',
                'type' => 'culinary',
                'lat' => 1.1550000,
                'lng' => 104.0050000,
                'address' => 'Kawasan Harbour Bay, Batu Ampar, Kota Batam',
                'kecamatan' => 'Batu Ampar',
                'rating' => 4.60,
                'review_count' => 1250,
                'photo_url' => 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=300&h=300&fit=crop',
                'description' => 'Restoran makanan laut tepi pantai dengan pemandangan sunset dan gedung Singapura.',
                'estimated_cost_idr' => 200000,
                'estimated_visit_minutes' => 90,
                'is_outdoor' => false,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catSeafood,
                'ticket_label' => 'Kisaran Rp 200rb',
            ],
            [
                'google_place_id' => 'BTM-DST-012',
                'name' => 'Tua Pek Kong Temple',
                'type' => 'attraction',
                'lat' => 1.1485000,
                'lng' => 104.0112000,
                'address' => 'Jl. Windsor Utama, Lubuk Baja, Kota Batam',
                'kecamatan' => 'Lubuk Baja',
                'rating' => 4.60,
                'review_count' => 980,
                'photo_url' => 'https://images.unsplash.com/photo-1548013146-72479768bada?w=300&h=300&fit=crop',
                'description' => 'Vihara tertua dan terbesar di Batam dengan arsitektur budaya Tionghoa yang megah.',
                'estimated_cost_idr' => 0,
                'estimated_visit_minutes' => 45,
                'is_outdoor' => true,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catBudaya,
                'ticket_label' => 'Gratis',
            ],
            [
                'google_place_id' => 'BTM-DST-013',
                'name' => 'Pantai Nongsa Neptune',
                'type' => 'attraction',
                'lat' => 1.1820000,
                'lng' => 104.1020000,
                'address' => 'Sambau, Kec. Nongsa, Kota Batam',
                'kecamatan' => 'Nongsa',
                'rating' => 4.50,
                'review_count' => 620,
                'photo_url' => 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=300&h=300&fit=crop',
                'description' => 'Pantai pasir putih tenang di kawasan resort eksklusif Nongsa.',
                'estimated_cost_idr' => 20000,
                'estimated_visit_minutes' => 90,
                'is_outdoor' => true,
                'category_tags_reviewed' => true,
                'source' => 'manual',
                'category' => $catPantai,
                'ticket_label' => 'Rp 20.000',
            ],
        ];

        foreach ($places as $item) {
            $cat = $item['category'];
            unset($item['category'], $item['ticket_label']);

            $place = Place::updateOrCreate(
                ['google_place_id' => $item['google_place_id']],
                $item
            );

            $place->categories()->sync([$cat->categories_id]);
        }

        // 3. Seed sample candidates for candidate badge count = 12
        for ($i = 1; $i <= 12; $i++) {
            PlaceCandidate::firstOrCreate(
                ['google_place_id' => "CAND-BTM-{$i}"],
                [
                    'name' => "Kandidat Tempat Wisata {$i}",
                    'type' => 'attraction',
                    'lat' => 1.1200000 + ($i * 0.005),
                    'lng' => 104.0300000 + ($i * 0.005),
                    'search_area' => 'Batam Kota',
                    'status' => 'pending',
                ]
            );
        }
    }
}
