<?php

namespace App\Jobs;

use App\Models\DiscoveryRun;
use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * F018 - Discovery on the queue, so the admin can leave the page while the
 * 36 Geoapify searches run. Progress goes into discovery_runs after every
 * area x type for the modal on the candidates page.
 */
class RunPlaceDiscovery implements ShouldQueue
{
    use Queueable;

    /**
     * Every search spends Geoapify credits; a failed run is started again by
     * the admin, not retried behind their back.
     */
    public int $tries = 1;

    public int $timeout = 900;

    public function __construct(public readonly DiscoveryRun $run) {}

    public function handle(PlaceDiscoveryService $discovery): void
    {
        // With QUEUE_CONNECTION=sync this runs inside the web request, whose
        // 60 second limit is far shorter than 36 searches.
        set_time_limit($this->timeout);

        $run = $this->run;
        $run->update(['status' => 'running', 'started_at' => now()]);
        Log::info('Discovery started', ['discovery_runs_id' => $run->discovery_runs_id]);

        $log = [];
        $discovery->discoverAll(function (string $area, string $type, ?array $result, ?string $error) use ($run, &$log) {
            $log[] = [
                'area' => $area,
                'type' => $type,
                'inserted' => $result['inserted'] ?? 0,
                'skipped' => $result['skipped_existing'] ?? 0,
                'error' => $error,
            ];

            $run->update([
                'done_steps' => count($log),
                'current_step' => "{$area} x {$type}",
                'inserted' => $run->inserted + ($result['inserted'] ?? 0),
                'skipped' => $run->skipped + ($result['skipped_existing'] ?? 0),
                'failed_steps' => $run->failed_steps + ($error === null ? 0 : 1),
                'log' => $log,
            ]);
        });

        $run->update(['status' => 'finished', 'current_step' => null, 'finished_at' => now()]);
        Log::info('Discovery finished', [
            'discovery_runs_id' => $run->discovery_runs_id,
            'inserted' => $run->inserted,
            'skipped' => $run->skipped,
            'failed_steps' => $run->failed_steps,
        ]);
    }

    public function failed(?Throwable $exception): void
    {
        $this->run->update([
            'status' => 'failed',
            'current_step' => null,
            'error' => $exception?->getMessage(),
            'finished_at' => now(),
        ]);
        Log::error('Discovery failed', ['discovery_runs_id' => $this->run->discovery_runs_id, 'error' => $exception?->getMessage()]);
    }
}
