<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PlaceCandidate;
use App\Services\Places\PlaceCandidateReviewService;
use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Http\Request;
use RuntimeException;

/**
 * F019 (US12, docs/prd design spec Section 3 & 14) - review kandidat
 * tempat hasil Discovery (F018) sebelum masuk sistem rekomendasi.
 */
class CandidateController extends Controller
{
    public function index(Request $request)
    {
        $candidates = PlaceCandidate::query()
            ->when($request->filled('search_area'), fn ($q) => $q->where('search_area', $request->string('search_area')))
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when(! $request->filled('status'), fn ($q) => $q->where('status', 'pending'))
            ->orderByDesc('created_at')
            ->paginate(25)
            ->withQueryString();

        return view('admin.candidates.index', [
            'candidates' => $candidates,
            'areas' => PlaceDiscoveryService::AREAS,
            'selectedArea' => $request->string('search_area')->toString(),
            'selectedStatus' => $request->string('status')->toString(),
        ]);
    }

    public function discover(PlaceDiscoveryService $service)
    {
        $result = $service->discoverAll();

        return redirect()->route('admin.candidates.index')->with(
            'status',
            "Discovery selesai: {$result['inserted']} kandidat baru, {$result['skipped_existing']} dilewati, ".count($result['failed']).' gagal.'
        );
    }

    public function approve(PlaceCandidate $candidate, PlaceCandidateReviewService $service)
    {
        try {
            $service->approve($candidate);
        } catch (RuntimeException $e) {
            return back()->with('error', "Gagal approve \"{$candidate->name}\": {$e->getMessage()}");
        }

        return back()->with('status', "\"{$candidate->name}\" disetujui dan dipromosikan ke katalog.");
    }

    public function reject(PlaceCandidate $candidate, PlaceCandidateReviewService $service)
    {
        $service->reject($candidate);

        return back()->with('status', "\"{$candidate->name}\" ditolak.");
    }

    public function bulkApprove(Request $request, PlaceCandidateReviewService $service)
    {
        $data = $request->validate(['ids' => ['required', 'array'], 'ids.*' => ['integer']]);

        $approved = 0;
        $failed = 0;

        foreach (PlaceCandidate::whereIn('place_candidates_id', $data['ids'])->get() as $candidate) {
            try {
                $service->approve($candidate);
                $approved++;
            } catch (RuntimeException) {
                $failed++;
            }
        }

        return back()->with('status', "{$approved} kandidat disetujui, {$failed} gagal.");
    }

    public function bulkReject(Request $request, PlaceCandidateReviewService $service)
    {
        $data = $request->validate(['ids' => ['required', 'array'], 'ids.*' => ['integer']]);

        foreach (PlaceCandidate::whereIn('place_candidates_id', $data['ids'])->get() as $candidate) {
            $service->reject($candidate);
        }

        return back()->with('status', count($data['ids']).' kandidat ditolak.');
    }
}
