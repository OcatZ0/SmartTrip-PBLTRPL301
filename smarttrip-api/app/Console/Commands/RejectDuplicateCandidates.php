<?php

namespace App\Console\Commands;

use App\Services\Places\PlaceCandidateReviewService;
use Illuminate\Console\Command;

/**
 * F019 - membersihkan kandidat pending yang ternyata duplikat tempat di
 * katalog atau kandidat lain (nama + jarak, lihat PlaceDuplicateFinder).
 */
class RejectDuplicateCandidates extends Command
{
    protected $signature = 'places:reject-duplicates';

    protected $description = 'Tolak kandidat pending yang duplikat tempat di katalog atau kandidat sebelumnya';

    public function handle(PlaceCandidateReviewService $service): int
    {
        $rejected = $service->rejectPendingDuplicates();

        $this->info("{$rejected} kandidat duplikat ditolak.");

        return self::SUCCESS;
    }
}
