<?php

namespace App\Console\Commands;

use App\Models\Place;
use App\Services\Places\PlaceEnrichmentService;
use Illuminate\Console\Command;
use RuntimeException;

/**
 * F020 - isi celah data tempat yang sudah ada di katalog lewat Gemini
 * (deskripsi ID/EN, tag kategori, durasi, is_outdoor, perkiraan biaya). Approve kandidat
 * sudah menjalankan enrichment sendiri; perintah ini untuk tempat seed,
 * input manual, atau yang enrichment-nya dulu gagal.
 */
class EnrichPlaces extends Command
{
    protected $signature = 'places:enrich
        {--place= : Hanya satu places_id}
        {--sleep=4 : Jeda detik antar panggilan Gemini (batas kuota per menit)}
        {--dry-run : Tampilkan fakta, jawaban AI dan yang akan diisi tanpa menyimpan}';

    protected $description = 'Isi field kosong tempat di katalog (deskripsi, tag kategori, durasi, is_outdoor, perkiraan biaya) lewat Gemini';

    public function handle(PlaceEnrichmentService $enrichment): int
    {
        $places = Place::query()
            ->when($this->option('place'), fn ($query, $placeId) => $query->whereKey($placeId))
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
                if ($this->option('dry-run')) {
                    $this->showPlan($place, $enrichment->plan($place));

                    continue;
                }

                $filled = $enrichment->enrich($place);
                $rows[] = [$place->places_id, $place->name, $filled === [] ? '-' : implode(', ', $filled)];
            } catch (RuntimeException $exception) {
                $failed++;
                // Gemini errors are multi-line JSON; keep the table one row per place.
                $message = preg_replace('/\s+/', ' ', $exception->getMessage());
                $rows[] = [$place->places_id, $place->name, 'GAGAL: '.mb_strimwidth($message, 0, 80, '...')];
            }
        }

        if ($this->option('dry-run')) {
            $this->info('Dry run: tidak ada yang disimpan.');

            return $failed > 0 ? self::FAILURE : self::SUCCESS;
        }

        $this->table(['ID', 'Tempat', 'Diisi'], $rows);

        if ($failed > 0) {
            $this->warn("{$failed} tempat gagal, jalankan lagi nanti untuk mencoba ulang.");

            return self::FAILURE;
        }

        $this->info('Selesai. Tempat yang diisi AI muncul di dashboard admin sebagai "hasil AI belum direview".');

        return self::SUCCESS;
    }

    private function showPlan(Place $place, array $plan): void
    {
        $this->newLine();
        $this->line("<options=bold>#{$place->places_id} {$place->name}</> ({$place->type}, ".($place->kecamatan ?: '-').')');
        $this->line('Fakta untuk AI:');
        foreach ($plan['facts'] ?: ['(tidak ada)'] as $fact) {
            $this->line("  - {$fact}");
        }
        $this->line('Jawaban AI (setelah dibersihkan):');
        $this->line('  '.json_encode($plan['answer'], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES));
        $this->line('Uji kewajaran:');
        foreach ($plan['notes'] ?: ['lolos semua'] as $note) {
            $this->line("  - {$note}");
        }
        $this->line('Akan diisi: '.($plan['filled'] === [] ? '-' : implode(', ', $plan['filled'])));
        foreach ($plan['updates'] as $field => $value) {
            $this->line("  {$field}: ".(is_bool($value) ? ($value ? 'true' : 'false') : (string) $value));
        }
    }
}
