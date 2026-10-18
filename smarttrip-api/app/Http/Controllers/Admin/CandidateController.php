<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Jobs\RunPlaceDiscovery;
use App\Models\DiscoveryRun;
use App\Models\PlaceCandidate;
use App\Services\Places\PlaceCandidateReviewService;
use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use RuntimeException;

/**
 * F019 (US12, docs/prd design spec Section 3 & 14) - review kandidat
 * tempat hasil Discovery (F018) sebelum masuk sistem rekomendasi.
 */
class CandidateController extends Controller
{
    /**
     * A queued run the worker never picked up, or a running one that stopped
     * reporting (the worker died), would block Discovery for good.
     */
    private const STALE_AFTER_MINUTES = 15;

    public function index(Request $request)
    {
        $search = $request->string('search')->trim()->toString();
        $selectedArea = $request->string('search_area')->toString();
        $selectedType = $request->string('type')->toString();
        $selectedStatus = $request->string('status')->toString() ?: 'pending';

        // Every filter but the status one, so the status tabs count what the other filters leave.
        $filtered = fn () => PlaceCandidate::query()
            ->when($search !== '', function ($candidateQuery) use ($search) {
                $term = '%'.mb_strtolower($search).'%';
                $candidateQuery->where(fn ($searchQuery) => $searchQuery
                    ->whereRaw('LOWER(name) LIKE ?', [$term])
                    ->orWhereRaw('LOWER(external_place_id) LIKE ?', [$term]));
            })
            ->when($selectedArea !== '', fn ($candidateQuery) => $candidateQuery->where('search_area', $selectedArea))
            ->when($selectedType !== '', fn ($candidateQuery) => $candidateQuery->where('type', $selectedType));

        $candidates = $filtered()
            ->where('status', $selectedStatus)
            ->orderByDesc('created_at')
            ->paginate(25)
            ->withQueryString();

        $statusCounts = $filtered()
            ->selectRaw('status, COUNT(*) AS total')
            ->groupBy('status')
            ->pluck('total', 'status');

        return view('admin.candidates.index', [
            'candidates' => $candidates,
            'areas' => array_keys(PlaceDiscoveryService::AREAS),
            'search' => $search,
            'selectedArea' => $selectedArea,
            'selectedType' => $selectedType,
            'selectedStatus' => $selectedStatus,
            'statusCounts' => $statusCounts,
            'discoveryRun' => $this->runPayload(DiscoveryRun::with('user')->latest('discovery_runs_id')->first()),
        ]);
    }

    /**
     * Queues a Discovery run; the modal follows it through discoveryStatus().
     */
    public function discover(Request $request)
    {
        $activeRun = $this->activeRun();
        if ($activeRun !== null) {
            return $request->expectsJson()
                ? response()->json(['message' => 'Discovery masih berjalan.', 'run' => $this->runPayload($activeRun)], 409)
                : back()->with('error', 'Discovery masih berjalan, tunggu sampai selesai.');
        }

        $run = DiscoveryRun::create([
            'users_id' => $request->user()->users_id,
            'status' => 'queued',
            'total_steps' => PlaceDiscoveryService::stepCount(),
        ]);
        RunPlaceDiscovery::dispatch($run);

        // With QUEUE_CONNECTION=sync the run has already finished here.
        $run->refresh()->load('user');
        if ($request->expectsJson()) {
            return response()->json(['run' => $this->runPayload($run)], 202);
        }

        return redirect()->route('admin.candidates.index')->with('status', $run->status === 'finished'
            ? "Discovery selesai: {$run->inserted} kandidat baru, {$run->skipped} dilewati, {$run->failed_steps} gagal."
            : 'Discovery dijalankan di latar belakang.');
    }

    public function discoveryStatus()
    {
        $this->activeRun();

        return response()->json(['run' => $this->runPayload(DiscoveryRun::with('user')->latest('discovery_runs_id')->first())]);
    }

    private function activeRun(): ?DiscoveryRun
    {
        $run = DiscoveryRun::active()->latest('discovery_runs_id')->first();
        if ($run === null || $run->updated_at->gt(now()->subMinutes(self::STALE_AFTER_MINUTES))) {
            return $run;
        }

        $run->update([
            'status' => 'failed',
            'current_step' => null,
            'error' => $run->status === 'queued'
                ? 'Worker queue tidak mengambil Discovery ini. Pastikan Scheduled Task queue:work berjalan di server.'
                : 'Discovery berhenti tanpa kabar, kemungkinan worker mati di tengah jalan.',
            'finished_at' => now(),
        ]);
        Log::warning('Discovery run marked stale', ['discovery_runs_id' => $run->discovery_runs_id]);

        return null;
    }

    /**
     * @return array<string, mixed>|null
     */
    private function runPayload(?DiscoveryRun $run): ?array
    {
        if ($run === null) {
            return null;
        }

        return [
            'id' => $run->discovery_runs_id,
            'status' => $run->status,
            'total_steps' => $run->total_steps,
            'done_steps' => $run->done_steps,
            'current_step' => $run->current_step,
            'inserted' => $run->inserted,
            'skipped' => $run->skipped,
            'failed_steps' => $run->failed_steps,
            'log' => $run->log ?? [],
            'error' => $run->error,
            'started_by' => $run->user?->name,
            'created_at' => $run->created_at?->toIso8601String(),
            'started_at' => $run->started_at?->toIso8601String(),
            'finished_at' => $run->finished_at?->toIso8601String(),
        ];
    }

    public function approve(PlaceCandidate $candidate, PlaceCandidateReviewService $service)
    {
        try {
            $place = $service->approve($candidate);
        } catch (RuntimeException $exception) {
            return back()->with('error', "Gagal menyetujui \"{$candidate->name}\": {$exception->getMessage()}");
        }

        if ($place === null) {
            return back()->with('error', "\"{$candidate->name}\" tidak ditambahkan: Google Maps mencatat tempat ini tutup permanen, jadi kandidatnya ditolak. Kalau tempatnya masih buka, tambahkan lewat Tambah Tempat.");
        }

        return back()->with('status', "\"{$candidate->name}\" disetujui dan dipromosikan ke katalog.");
    }

    public function reject(PlaceCandidate $candidate, PlaceCandidateReviewService $service)
    {
        try {
            $service->reject($candidate);
        } catch (RuntimeException $exception) {
            return back()->with('error', "Gagal menolak \"{$candidate->name}\": {$exception->getMessage()}");
        }

        return back()->with('status', "\"{$candidate->name}\" ditolak.");
    }

    public function bulkApprove(Request $request, PlaceCandidateReviewService $service)
    {
        $data = $request->validate(['ids' => ['required', 'array'], 'ids.*' => ['integer']]);

        $approved = 0;
        $closed = 0;
        $failed = 0;

        foreach (PlaceCandidate::whereIn('place_candidates_id', $data['ids'])->get() as $candidate) {
            try {
                $service->approve($candidate) === null ? $closed++ : $approved++;
            } catch (RuntimeException) {
                $failed++;
            }
        }

        $closedNote = $closed > 0 ? ", {$closed} ditolak karena tutup permanen di Google Maps" : '';

        return back()->with('status', "{$approved} kandidat disetujui{$closedNote}, {$failed} gagal.");
    }

    public function bulkReject(Request $request, PlaceCandidateReviewService $service)
    {
        $data = $request->validate(['ids' => ['required', 'array'], 'ids.*' => ['integer']]);

        $rejected = 0;
        $skipped = 0;

        foreach (PlaceCandidate::whereIn('place_candidates_id', $data['ids'])->get() as $candidate) {
            try {
                $service->reject($candidate);
                $rejected++;
            } catch (RuntimeException) {
                $skipped++;
            }
        }

        return back()->with('status', "{$rejected} kandidat ditolak, {$skipped} dilewati karena statusnya bukan menunggu.");
    }
}
