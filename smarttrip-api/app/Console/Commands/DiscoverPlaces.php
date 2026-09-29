<?php

namespace App\Console\Commands;

use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Console\Command;

/**
 * F018 - admin trigger (manual, bukan cron harian - lihat docs/prd design
 * spec Section 3) buat fase Discovery: loop 12 kecamatan x 3 kategori,
 * hasil masuk place_candidates buat direview admin (F019).
 */
class DiscoverPlaces extends Command
{
    protected $signature = 'places:discover';

    protected $description = 'Jalankan Discovery Google Places (Text Search) untuk semua kombinasi kecamatan x kategori di Batam';

    public function handle(PlaceDiscoveryService $service): int
    {
        $this->info('Menjalankan Discovery...');

        $result = $service->discoverAll();

        $this->table(
            ['Kombinasi area x kategori', 'Kandidat baru ditambahkan', 'Dilewati (sudah ada)', 'Gagal'],
            [[$result['areas_searched'], $result['inserted'], $result['skipped_existing'], count($result['failed'])]]
        );

        foreach ($result['failed'] as $message) {
            $this->error($message);
        }

        return $result['failed'] === [] ? self::SUCCESS : self::FAILURE;
    }
}
