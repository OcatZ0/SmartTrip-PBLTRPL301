<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Models\PlaceCandidate;
use RuntimeException;

/**
 * F018 (docs/prd design spec Section 3 fase 1) - loop area x kategori,
 * satu trigger = satu operasi bootstrap penuh (bukan satu API call). PRD
 * tidak menyebutkan daftar kecamatan secara eksplisit ("sekitar belasan
 * area") - 12 kecamatan resmi Kota Batam dipakai sebagai asumsi.
 */
class PlaceDiscoveryService
{
    public const AREAS = [
        'Batu Ampar', 'Lubuk Baja', 'Sekupang', 'Nongsa', 'Batam Kota',
        'Sagulung', 'Bengkong', 'Sungai Beduk', 'Batu Aji', 'Bulang',
        'Galang', 'Belakang Padang',
    ];

    public const CATEGORY_QUERIES = [
        'attraction' => 'tempat wisata',
        'culinary' => 'tempat kuliner',
        'lodging' => 'hotel',
    ];

    public function __construct(private readonly GooglePlacesDiscoveryClient $client) {}

    /**
     * Kegagalan di satu kombinasi (misal 403 sementara dari Google) tidak
     * menggagalkan seluruh batch - kandidat yang sudah ke-insert dari
     * kombinasi sebelumnya tetap tersimpan (tiap PlaceCandidate::create()
     * langsung commit, tidak dibungkus satu transaksi besar), dan sisa
     * kombinasi lain tetap dicoba supaya satu error tidak membuang seluruh
     * progres bootstrap.
     *
     * @return array{inserted: int, skipped_existing: int, areas_searched: int, failed: array<int, string>}
     */
    public function discoverAll(): array
    {
        $inserted = 0;
        $skipped = 0;
        $failed = [];

        foreach (self::AREAS as $area) {
            foreach (self::CATEGORY_QUERIES as $type => $queryLabel) {
                try {
                    $result = $this->discoverOne($area, $type, $queryLabel);
                    $inserted += $result['inserted'];
                    $skipped += $result['skipped_existing'];
                } catch (RuntimeException $e) {
                    $failed[] = "{$area} x {$type}: {$e->getMessage()}";
                }
            }
        }

        return [
            'inserted' => $inserted,
            'skipped_existing' => $skipped,
            'areas_searched' => count(self::AREAS) * count(self::CATEGORY_QUERIES),
            'failed' => $failed,
        ];
    }

    /**
     * @return array{inserted: int, skipped_existing: int}
     */
    private function discoverOne(string $area, string $type, string $queryLabel): array
    {
        $results = $this->client->textSearch("{$queryLabel} di {$area}, Batam, Indonesia");

        $inserted = 0;
        $skipped = 0;

        foreach ($results as $result) {
            if ($this->alreadyKnown($result['google_place_id'])) {
                $skipped++;

                continue;
            }

            PlaceCandidate::create([
                'google_place_id' => $result['google_place_id'],
                'name' => $result['name'],
                'type' => $type,
                'lat' => $result['lat'],
                'lng' => $result['lng'],
                'search_area' => $area,
                'status' => 'pending',
            ]);
            $inserted++;
        }

        return ['inserted' => $inserted, 'skipped_existing' => $skipped];
    }

    /**
     * Idempotensi (Section 3, 1a): dicek terhadap places DAN place_candidates
     * di status apapun termasuk rejected - supaya tempat yang sudah pernah
     * ditolak admin tidak terus muncul lagi tiap Discovery di-re-run.
     */
    private function alreadyKnown(string $googlePlaceId): bool
    {
        return Place::withTrashed()->where('google_place_id', $googlePlaceId)->exists()
            || PlaceCandidate::where('google_place_id', $googlePlaceId)->exists();
    }
}
