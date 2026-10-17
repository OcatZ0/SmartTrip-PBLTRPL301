<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlaceReview;
use App\Models\Trip;
use App\Services\Places\GeoapifyPlacesClient;
use Illuminate\Support\Carbon;

/**
 * F024 (US14, SKPPL UC-022) - status sinkronisasi (kapan discovery dan
 * pelengkapan data terakhir jalan, kandidat pending, kredit Geoapify hari
 * ini), ringkasan (5 tempat paling di-wishlist, rata-rata rating in-app,
 * volume trip), dan tiga kolom kerja: kandidat baru, tempat tanpa harga,
 * dan tag hasil AI yang belum dicek admin.
 *
 * "Kapan discovery/pelengkapan terakhir jalan" tidak punya tabel log
 * tersendiri di skema (PRD tidak memintanya) - diturunkan dari timestamp
 * data yang sudah ada: MAX(place_candidates.created_at) buat discovery,
 * MAX(places.created_at WHERE source dari provider) buat pelengkapan
 * (places itu cuma dibuat lewat alur approve/enrichment, F019).
 */
class DashboardController extends Controller
{
    /**
     * How many items each work column on the dashboard previews.
     */
    private const COLUMN_PREVIEW = 3;

    private const MOST_WISHLISTED_LIMIT = 5;

    public function index()
    {
        return view('admin.dashboard.index', [
            'pendingCandidates' => PlaceCandidate::where('status', 'pending')->count(),
            // max() adalah query agregat mentah - tidak lewat hydration
            // model, jadi hasilnya string biasa dari DB, bukan Carbon.
            'lastDiscoveryAt' => self::toCarbon(PlaceCandidate::max('created_at')),
            // Newest place promoted from a candidate (approve also runs the Gemini enrichment).
            'lastApprovedAt' => self::toCarbon(Place::whereIn('source', ['google', 'geoapify'])->max('created_at')),
            'quotaUsed' => GeoapifyPlacesClient::creditsUsedToday(),
            'quotaLimit' => (int) config('services.geoapify.daily_credits'),
            'mostWishlistedPlaces' => Place::whereHas('wishlistedIn')
                ->withCount('wishlistedIn')
                ->orderByDesc('wishlisted_in_count')
                ->orderBy('name')
                ->take(self::MOST_WISHLISTED_LIMIT)
                ->get(),
            'averageInAppRating' => PlaceReview::avg('rating'),
            'tripVolume' => Trip::count(),
            'placesMissingCost' => Place::whereNull('estimated_cost_idr')->count(),
            'placesTagsNotReviewed' => Place::where('category_tags_reviewed', false)->count(),
            'recentCandidates' => PlaceCandidate::where('status', 'pending')
                ->latest()
                ->take(self::COLUMN_PREVIEW)
                ->get(),
            'missingCostList' => Place::whereNull('estimated_cost_idr')
                ->orderBy('name')
                ->take(self::COLUMN_PREVIEW)
                ->get(),
            'untaggedList' => Place::where('category_tags_reviewed', false)
                ->with('categories')
                ->latest()
                ->take(self::COLUMN_PREVIEW)
                ->get(),
        ]);
    }

    private static function toCarbon(?string $value): ?Carbon
    {
        return $value !== null ? Carbon::parse($value) : null;
    }
}
