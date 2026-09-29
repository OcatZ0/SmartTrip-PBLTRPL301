<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlaceReview;
use App\Models\Trip;
use Illuminate\Support\Carbon;

/**
 * F024 (US14, docs/prd design spec Section 14) - status sinkronisasi
 * (kapan discovery/enrichment terakhir jalan, kandidat pending, indikator
 * kuota Enterprise) + dashboard analitik (tempat paling di-wishlist,
 * rata-rata rating in-app, volume trip, tempat butuh perhatian).
 *
 * "Kapan discovery/enrichment terakhir jalan" tidak punya tabel log
 * tersendiri di skema (PRD tidak memintanya) - diturunkan dari timestamp
 * data yang sudah ada: MAX(place_candidates.created_at) buat discovery,
 * MAX(places.created_at WHERE source=google) buat enrichment (places
 * asal Google cuma dibuat lewat alur approve/enrichment, F019).
 */
class DashboardController extends Controller
{
    public function index()
    {
        $quotaLimit = (int) config('services.google.places_monthly_quota');
        $quotaUsed = Place::where('source', 'google')
            ->whereBetween('created_at', [now()->startOfMonth(), now()->endOfMonth()])
            ->count();

        return view('admin.dashboard.index', [
            'pendingCandidates' => PlaceCandidate::where('status', 'pending')->count(),
            // max() adalah query agregat mentah - tidak lewat hydration
            // model, jadi hasilnya string biasa dari DB, bukan Carbon.
            'lastDiscoveryAt' => self::toCarbon(PlaceCandidate::max('created_at')),
            'lastEnrichmentAt' => self::toCarbon(Place::where('source', 'google')->max('created_at')),
            'quotaUsed' => $quotaUsed,
            'quotaLimit' => $quotaLimit,
            'mostWishlistedPlaces' => Place::withCount('wishlistedIn')
                ->orderByDesc('wishlisted_in_count')
                ->take(5)
                ->get()
                ->filter(fn ($place) => $place->wishlisted_in_count > 0)
                ->values(),
            'averageInAppRating' => PlaceReview::avg('rating'),
            'tripVolume' => Trip::count(),
            'placesMissingCost' => Place::whereNull('estimated_cost_idr')->count(),
            'placesTagsNotReviewed' => Place::where('category_tags_reviewed', false)->count(),
        ]);
    }

    private static function toCarbon(?string $value): ?Carbon
    {
        return $value !== null ? Carbon::parse($value) : null;
    }
}
