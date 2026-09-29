<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PlaceCandidate;

/**
 * F014/F024: "needs attention" overview + sync/quota status (docs/prd
 * Section 8). Kandidat pending sudah terhubung sejak F019 - sisanya
 * (tempat butuh perhatian, kuota Google Places) masih stub sampai F024.
 */
class DashboardController extends Controller
{
    public function index()
    {
        return view('admin.dashboard.index', [
            'pendingCandidates' => PlaceCandidate::where('status', 'pending')->count(),
        ]);
    }
}
