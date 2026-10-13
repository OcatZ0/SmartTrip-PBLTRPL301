<?php

namespace App\Console\Commands;

use App\Models\Place;
use App\Services\Places\PlaceEnrichmentService;
use Illuminate\Console\Command;
use RuntimeException;

/**
 * F020 - isi celah data tempat yang sudah ada di katalog lewat Gemini
 * (deskripsi ID/EN, tag kategori, durasi, is_outdoor). Approve kandidat
 * sudah menjalankan enrichment sendiri; perintah ini untuk tempat seed,
 * input manual, atau yang enrichment-nya dulu gagal.
 */
class EnrichPlaces extends Command
{
    protected $signature = 'places:enrich
        {--place= : Hanya satu places_id}
        {--sleep=4 : Jeda detik antar panggilan Gemini (batas kuota per menit)}';

    protected $description = 'Isi field kosong tempat di katalog (deskripsi, tag kategori, durasi, is_outdoor) lewat Gemini';

    public function handle(PlaceEnrichmentService $enrichment): int
    {
        $places = Place::query()
            ->when($this->option('place'), fn ($query, $id) => $query->whereKey($id))
            ->orderBy('places_id')
            ->get()
            ->filter(fn (Place $place) => $enrichment->needsEnrichment($place))
            ->values();

        if ($places->isEmpty()) {
            $this->info('Tidak ada tempat yang perlu di-enrich.');

            return self::SUCCESS;
        }

        $this->info("Enrichment {$places->count()} tempat...");
        $sleep = max(0, (int) $this->option('sleep'));
        $rows = [];
        $failed = 0;

        foreach ($places as $index => $place) {
            if ($index > 0 && $sleep > 0) {
                sleep($sleep);
            }

            try {
                $filled = $enrichment->enrich($place);
                $rows[] = [$place->places_id, $place->name, $filled === [] ? '-' : implode(', ', $filled)];
            } catch (RuntimeException $e) {
                $failed++;
                $rows[] = [$place->places_id, $place->name, 'GAGAL: '.mb_strimwidth($e->getMessage(), 0, 80, '...')];
            }
        }

        $this->table(['ID', 'Tempat', 'Diisi'], $rows);

        if ($failed > 0) {
            $this->warn("{$failed} tempat gagal, jalankan lagi nanti untuk mencoba ulang.");

            return self::FAILURE;
        }

        $this->info('Selesai. Tempat yang diisi AI muncul di dashboard admin sebagai "hasil AI belum direview".');

        return self::SUCCESS;
    }
}
