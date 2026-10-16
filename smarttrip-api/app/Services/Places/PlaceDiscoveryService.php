<?php

namespace App\Services\Places;

use App\Models\PlaceCandidate;
use RuntimeException;

/**
 * F018 (docs/prd design spec Section 3 fase 1) - loop area x kategori,
 * satu trigger = satu operasi bootstrap penuh (bukan satu API call). Sejak
 * 2026-10-13 lewat Geoapify, yang mencari di dalam lingkaran, bukan nama
 * area: tiap kecamatan diwakili titik tengah + radius kira-kira (bukan batas
 * administratif resmi), cukup untuk mengelompokkan kandidat buat review.
 */
class PlaceDiscoveryService
{
    /** @var array<string, array{lat: float, lng: float, radius: int}> */
    public const AREAS = [
        'Batu Ampar' => ['lat' => 1.163, 'lng' => 104.003, 'radius' => 3000],
        'Lubuk Baja' => ['lat' => 1.143, 'lng' => 104.010, 'radius' => 2500],
        'Sekupang' => ['lat' => 1.118, 'lng' => 103.948, 'radius' => 5000],
        'Nongsa' => ['lat' => 1.165, 'lng' => 104.105, 'radius' => 7000],
        'Batam Kota' => ['lat' => 1.128, 'lng' => 104.052, 'radius' => 4000],
        'Sagulung' => ['lat' => 1.045, 'lng' => 103.960, 'radius' => 4000],
        'Bengkong' => ['lat' => 1.153, 'lng' => 104.033, 'radius' => 2500],
        'Sungai Beduk' => ['lat' => 1.075, 'lng' => 104.045, 'radius' => 5000],
        'Batu Aji' => ['lat' => 1.050, 'lng' => 103.985, 'radius' => 3500],
        'Bulang' => ['lat' => 1.000, 'lng' => 103.880, 'radius' => 8000],
        'Galang' => ['lat' => 0.760, 'lng' => 104.200, 'radius' => 10000],
        'Belakang Padang' => ['lat' => 1.160, 'lng' => 103.895, 'radius' => 4000],
    ];

    /**
     * Geoapify category keys per places.type. leisure.park is left out on
     * purpose: in Batam it mostly returns residential fields and playgrounds.
     */
    public const CATEGORY_QUERIES = [
        'attraction' => 'tourism.attraction,tourism.sights,entertainment.museum,beach,commercial.shopping_mall',
        'culinary' => 'catering.restaurant,catering.cafe',
        'lodging' => 'accommodation.hotel',
    ];

    public function __construct(
        private readonly GeoapifyPlacesClient $client,
        private readonly PlaceDuplicateFinder $duplicates,
    ) {}

    /**
     * Kegagalan di satu kombinasi (misal 403 sementara dari Geoapify) tidak
     * menggagalkan seluruh batch - kandidat yang sudah ke-insert dari
     * kombinasi sebelumnya tetap tersimpan (tiap PlaceCandidate::create()
     * langsung commit, tidak dibungkus satu transaksi besar), dan sisa
     * kombinasi lain tetap dicoba supaya satu error tidak membuang seluruh
     * progres bootstrap.
     *
     * [onStep] gets (area, type, result or null, error or null) after every
     * area x type, for the progress modal.
     *
     * @return array{inserted: int, skipped_existing: int, areas_searched: int, failed: array<int, string>}
     */
    public function discoverAll(?callable $onStep = null): array
    {
        $inserted = 0;
        $skipped = 0;
        $failed = [];

        foreach (self::AREAS as $area => $circle) {
            foreach (self::CATEGORY_QUERIES as $type => $categories) {
                try {
                    $result = $this->discoverOne($area, $circle, $type, $categories);
                    $inserted += $result['inserted'];
                    $skipped += $result['skipped_existing'];
                    if ($onStep !== null) {
                        $onStep($area, $type, $result, null);
                    }
                } catch (RuntimeException $exception) {
                    $failed[] = "{$area} x {$type}: {$exception->getMessage()}";
                    if ($onStep !== null) {
                        $onStep($area, $type, null, $exception->getMessage());
                    }
                }
            }
        }

        return [
            'inserted' => $inserted,
            'skipped_existing' => $skipped,
            'areas_searched' => self::stepCount(),
            'failed' => $failed,
        ];
    }

    public static function stepCount(): int
    {
        return count(self::AREAS) * count(self::CATEGORY_QUERIES);
    }

    /**
     * @return array{inserted: int, skipped_existing: int}
     */
    private function discoverOne(string $area, array $circle, string $type, string $categories): array
    {
        $results = $this->client->search($circle['lat'], $circle['lng'], $circle['radius'], $categories);

        $inserted = 0;
        $skipped = 0;

        foreach ($results as $result) {
            if ($this->alreadyKnown($result)) {
                $skipped++;

                continue;
            }

            PlaceCandidate::create([
                'external_place_id' => $result['external_place_id'],
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
     * ditolak admin tidak terus muncul lagi tiap Discovery di-re-run. Selain
     * ID, dicek juga nama + jarak (PlaceDuplicateFinder), karena tempat seed
     * atau input manual bisa tanpa ID dan OSM sering memetakan satu tempat
     * dua kali.
     *
     * @param  array{external_place_id: string, name: string, lat: float, lng: float}  $result
     */
    private function alreadyKnown(array $result): bool
    {
        [$externalPlaceId, $name, $lat, $lng] = [$result['external_place_id'], $result['name'], $result['lat'], $result['lng']];

        return $this->duplicates->findPlace($externalPlaceId, $name, $lat, $lng) !== null
            || $this->duplicates->findCandidate($externalPlaceId, $name, $lat, $lng) !== null;
    }
}
