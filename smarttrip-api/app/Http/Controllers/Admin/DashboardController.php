<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Models\PlaceReview;
use App\Services\ApiUsage;
use App\Services\Places\GeoapifyPlacesClient;
use App\Services\Places\GooglePlaceLookupClient;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * F024 (US14, SKPPL UC-022) - status sinkronisasi (kapan discovery dan
 * pelengkapan data terakhir jalan, kandidat pending), kuota gratis tiap API
 * luar (Gemini, SerpApi, Geoapify, OpenRouteService), ringkasan (5 tempat paling di-wishlist, rata-rata rating in-app,
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

    public function index(GooglePlaceLookupClient $google)
    {
        return view('admin.dashboard.index', [
            'placeCount' => Place::count(),
            'apiQuotas' => $this->apiQuotas($google),
            'pendingCandidates' => PlaceCandidate::where('status', 'pending')->count(),
            // max() adalah query agregat mentah - tidak lewat hydration
            // model, jadi hasilnya string biasa dari DB, bukan Carbon.
            'lastDiscoveryAt' => self::toCarbon(PlaceCandidate::max('created_at')),
            // Newest place promoted from a candidate (approve also runs the Gemini enrichment).
            'lastApprovedAt' => self::toCarbon(Place::whereIn('source', ['google', 'geoapify'])->max('created_at')),
            'mostWishlistedPlaces' => Place::whereHas('wishlistedIn')
                ->withCount('wishlistedIn')
                ->orderByDesc('wishlisted_in_count')
                ->orderBy('name')
                ->take(self::MOST_WISHLISTED_LIMIT)
                ->get(),
            'averageInAppRating' => PlaceReview::avg('rating'),
            // v_trips_admin hides share tokens and budget; the admin DB role cannot read trips directly.
            'tripVolume' => DB::table('v_trips_admin')->whereNull('deleted_at')->count(),
            // "Data belum lengkap": how many places miss each kind of data.
            'dataGaps' => collect(Place::DATA_GAPS)->map(fn (array $gap, string $key) => [
                'label' => $gap[0],
                'hint' => $gap[1],
                'count' => Place::missing($key)->count(),
                'url' => route('admin.places.index', ['kurang' => $key]),
            ])->all(),
            'incompletePlaceCount' => Place::incomplete()->count(),
            'recentCandidates' => PlaceCandidate::where('status', 'pending')
                ->latest()
                ->take(self::COLUMN_PREVIEW)
                ->get(),
        ]);
    }

    /**
     * Free plan usage of every outside API, for the "Kuota API" card. used is
     * null when the number cannot be read (SerpApi not set up or unreachable).
     *
     * @return array<int, array{name: string, purpose: string, used: int|null, limit: int, period: string, resets: string}>
     */
    private function apiQuotas(GooglePlaceLookupClient $google): array
    {
        $wib = fn (Carbon $time) => $time->copy()->timezone('Asia/Jakarta');
        $serpApi = $google->account();

        return [
            [
                'name' => 'Gemini',
                'purpose' => 'Deskripsi, kata kunci, perkiraan data',
                'used' => ApiUsage::today(ApiUsage::GEMINI),
                'limit' => (int) config('services.gemini.daily_limit'),
                'period' => 'hari ini',
                'resets' => 'Reset '.$wib(ApiUsage::resetsAt(ApiUsage::GEMINI))->format('H.i').' WIB',
            ],
            [
                'name' => 'SerpApi',
                'purpose' => 'Google Maps, web dan Google Gambar',
                'used' => $serpApi['used_this_month'] ?? null,
                'limit' => $serpApi['searches_per_month'] ?? 250,
                'period' => 'bulan ini',
                'resets' => $serpApi === null
                    ? 'Tidak terbaca, periksa SERPAPI_API_KEY'
                    : ($serpApi['renews_on'] ? 'Reset '.Carbon::parse($serpApi['renews_on'])->translatedFormat('j M Y') : 'Reset bulanan'),
            ],
            [
                'name' => 'Geoapify',
                'purpose' => 'Discovery dan detail tempat',
                'used' => GeoapifyPlacesClient::creditsUsedToday(),
                'limit' => (int) config('services.geoapify.daily_credits'),
                'period' => 'kredit hari ini',
                'resets' => 'Reset '.$wib(now('UTC')->addDay()->startOfDay())->format('H.i').' WIB',
            ],
            [
                'name' => 'OpenRouteService',
                'purpose' => 'Rute jalan itinerary',
                'used' => ApiUsage::today(ApiUsage::OPENROUTESERVICE),
                'limit' => (int) config('services.openrouteservice.daily_limit'),
                'period' => 'hari ini',
                'resets' => 'Reset '.$wib(ApiUsage::resetsAt(ApiUsage::OPENROUTESERVICE))->format('H.i').' WIB',
            ],
        ];
    }

    private static function toCarbon(?string $value): ?Carbon
    {
        return $value !== null ? Carbon::parse($value) : null;
    }
}
