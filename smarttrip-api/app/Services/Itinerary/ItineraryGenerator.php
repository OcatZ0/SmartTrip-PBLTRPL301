<?php

namespace App\Services\Itinerary;

use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\Trip;
use Carbon\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use RuntimeException;

/**
 * docs/prd design spec Section 7: K-Means (pembagian hari) -> Weighted
 * TOPSIS (ranking kandidat) -> Nearest-Neighbor (urutan rute) -> Routes
 * API (polyline asli per segmen). Orkestrator - matematika murninya ada
 * di kelas lain di namespace ini (semua deterministik, testable sendiri).
 */
class ItineraryGenerator
{
    /**
     * "Melebihi cukup jauh" di langkah 6f tidak dikasih angka pasti oleh
     * PRD - 15% di atas estimasi kasar dipakai sebagai ambang "padat",
     * asumsi eksplisit.
     */
    private const OVERBUDGET_THRESHOLD = 1.15;

    private const DETOUR_FACTOR = 1.35;

    private const AVERAGE_SPEED_KMH = 27.5;

    public function __construct(private readonly OpenRouteServiceClient $routesClient) {}

    /**
     * @return array{days: array<int, array{day: ItineraryDay, tidak_muat: bool, padat: bool}>, dropped_wishlist_places: array<int, string>}
     */
    public function generate(Trip $trip): array
    {
        if (! $trip->interestCategories()->exists()) {
            throw new RuntimeException('Trip belum punya minat/bobot kriteria - panggil /weights dulu.');
        }

        if (! $trip->hasResolvedHotel()) {
            throw new RuntimeException('Trip belum punya hotel/titik awal - panggil /hotel dulu.');
        }

        $start = $trip->hotelCoordinates();
        $windowMinutes = $this->windowMinutes($trip);
        $tripCategoryIds = $trip->interestCategories()->pluck('categories.categories_id')->all();

        $wishlistStops = $this->normalizedWishlist($trip);

        $candidatePool = $this->scoredCandidatePool($trip, $wishlistStops, $tripCategoryIds, $start);

        $dayBuckets = $this->clusterIntoDays($trip->num_days, $wishlistStops);

        $usedPlaceIds = $wishlistStops->pluck('places_id')->filter()->flip();
        $droppedLabels = [];

        $days = [];
        $dayCount = count($dayBuckets);

        // Indexed loop, not foreach: overflow cascading mutates
        // $dayBuckets[$dayNumber + 1] below, and foreach's by-value
        // iteration isn't guaranteed to see writes to not-yet-visited
        // elements of the same array it's iterating.
        for ($dayNumber = 0; $dayNumber < $dayCount; $dayNumber++) {
            $bucket = $dayBuckets[$dayNumber];
            $stops = $bucket['stops'];
            $centroid = $bucket['centroid'] ?? $start;

            [$stops, $overflow] = $this->fitWithinBudget($stops, $start, $windowMinutes, $centroid);

            // Overflow cascades to the next day; the last day has nowhere
            // to push to, so those items are dropped and the day is
            // flagged "tidak muat" (docs/prd design spec Section 7 langkah
            // 6b: "kalau tetap tidak muat sampai hari terakhir").
            $tidakMuat = false;
            if ($overflow !== [] && isset($dayBuckets[$dayNumber + 1])) {
                $dayBuckets[$dayNumber + 1]['stops'] = array_merge($dayBuckets[$dayNumber + 1]['stops'], $overflow);
            } elseif ($overflow !== []) {
                $tidakMuat = true;
                foreach ($overflow as $item) {
                    $droppedLabels[] = $item['label'];
                }
            }

            $stops = $this->fillEmptySlots($stops, $centroid, $start, $windowMinutes, $candidatePool, $usedPlaceIds);

            foreach ($stops as $stop) {
                if ($stop['places_id'] !== null) {
                    $usedPlaceIds[$stop['places_id']] = true;
                }
            }

            // US4 acceptance criteria: pool kandidat tidak cukup (hari
            // berakhir kosong sama sekali) juga diperlakukan sebagai
            // "tidak muat", bukan cuma kasus overflow di atas.
            if ($stops === []) {
                $tidakMuat = true;
            }

            $days[$dayNumber] = [
                'stops' => $stops,
                'centroid' => $centroid,
                'tidak_muat' => $tidakMuat,
            ];
        }

        return DB::transaction(function () use ($trip, $days, $start, $droppedLabels) {
            $trip->days()->delete();

            $result = [];

            foreach ($days as $dayNumber => $day) {
                $result[] = $this->persistDay($trip, $dayNumber + 1, $day, $start);
            }

            return ['days' => $result, 'dropped_wishlist_places' => $droppedLabels];
        });
    }

    private function windowMinutes(Trip $trip): int
    {
        $start = Carbon::parse($trip->daily_start_time);
        $end = Carbon::parse($trip->daily_end_time);

        // Carbon 3's diffInMinutes() is signed (not absolute) by default -
        // $start->diff($end) with $end after $start gives a positive value;
        // the reverse call silently returned a negative number here before.
        return max(0, $start->diffInMinutes($end, true));
    }

    /**
     * @return Collection<int, array{wishlist_id: int, places_id: ?int, lat: float, lng: float, visit_minutes: int, source: string, label: string, topsis_score: ?float}>
     */
    private function normalizedWishlist(Trip $trip): Collection
    {
        // Wishlist yang tempatnya sudah di-soft-delete admin tidak ikut
        // digenerate (hilang dari rekomendasi), tapi barisnya tetap ada.
        return $trip->wishlistPlaces()->with('place')->get()
            ->reject(fn ($item) => $item->places_id !== null && $item->place->trashed())
            ->values()
            ->map(function ($item) {
            if ($item->places_id !== null) {
                return [
                    'wishlist_id' => $item->trip_wishlist_places_id,
                    'places_id' => $item->places_id,
                    'lat' => (float) $item->place->lat,
                    'lng' => (float) $item->place->lng,
                    'visit_minutes' => (int) ($item->place->estimated_visit_minutes ?? 60),
                    'source' => 'wishlist',
                    'label' => $item->place->name,
                    'topsis_score' => null,
                ];
            }

            return [
                'wishlist_id' => $item->trip_wishlist_places_id,
                'places_id' => null,
                'lat' => (float) $item->custom_lat,
                'lng' => (float) $item->custom_lng,
                'visit_minutes' => (int) $item->custom_visit_minutes,
                'source' => 'wishlist',
                'label' => $item->custom_name,
                'topsis_score' => null,
            ];
        });
    }

    /**
     * Langkah 5: matriks TOPSIS buat kandidat attraction/culinary di luar
     * wishlist (wishlist sudah pasti masuk, tidak perlu direkomendasikan).
     *
     * @return Collection<int, array{places_id: int, lat: float, lng: float, visit_minutes: int, cost: int, topsis_score: float}>
     */
    private function scoredCandidatePool(Trip $trip, Collection $wishlistStops, array $tripCategoryIds, array $start): Collection
    {
        $excludedIds = $wishlistStops->pluck('places_id')->filter()->all();

        $places = Place::query()
            ->whereIn('type', ['attraction', 'culinary'])
            ->where('business_status', '!=', 'closed_permanently')
            ->when($excludedIds !== [], fn ($q) => $q->whereNotIn('places_id', $excludedIds))
            ->with('categories')
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->get();

        if ($places->isEmpty()) {
            return collect();
        }

        $costEstimator = new PlaceCostEstimator($places);
        $ratingEstimator = new PlaceRatingEstimator($places);

        $matrix = [];
        foreach ($places as $place) {
            $matrix[$place->places_id] = [
                'kategori' => JaccardSimilarity::of($tripCategoryIds, $place->categories->pluck('categories_id')->all()),
                'jarak' => Haversine::km($start['lat'], $start['lng'], (float) $place->lat, (float) $place->lng),
                'anggaran' => $costEstimator->estimate($place),
                'rating' => $ratingEstimator->estimate($place),
            ];
        }

        $weights = [
            'kategori' => (float) $trip->weight_kategori,
            'jarak' => (float) $trip->weight_jarak,
            'anggaran' => (float) $trip->weight_anggaran,
            'rating' => (float) $trip->weight_rating,
        ];
        $isBenefit = ['kategori' => true, 'jarak' => false, 'anggaran' => false, 'rating' => true];

        $scores = Topsis::rank($matrix, $weights, $isBenefit);

        return $places->map(fn (Place $place) => [
            'places_id' => $place->places_id,
            'lat' => (float) $place->lat,
            'lng' => (float) $place->lng,
            'visit_minutes' => (int) ($place->estimated_visit_minutes ?? 60),
            'label' => $place->name,
            'topsis_score' => $scores[$place->places_id],
        ])->sortByDesc('topsis_score')->values();
    }

    /**
     * Langkah 6a: K-Means atas koordinat wishlist, k = num_days.
     *
     * @return array<int, array{stops: array<int, array<string, mixed>>, centroid: array{lat: float, lng: float}|null}>
     */
    private function clusterIntoDays(int $numDays, Collection $wishlistStops): array
    {
        $buckets = [];
        for ($i = 0; $i < $numDays; $i++) {
            $buckets[$i] = ['stops' => [], 'centroid' => null];
        }

        if ($wishlistStops->isEmpty()) {
            return $buckets;
        }

        $points = $wishlistStops->map(fn ($stop) => ['lat' => $stop['lat'], 'lng' => $stop['lng']])->values()->all();
        $assignments = KMeans::cluster($points, $numDays);

        $byCluster = [];
        foreach ($wishlistStops->values()->all() as $index => $stop) {
            $byCluster[$assignments[$index]][] = $stop;
        }

        $dayNumber = 0;
        foreach ($byCluster as $stops) {
            $buckets[$dayNumber]['stops'] = $stops;
            $buckets[$dayNumber]['centroid'] = KMeans::centroid(array_map(
                fn ($s) => ['lat' => $s['lat'], 'lng' => $s['lng']],
                $stops
            ));
            $dayNumber++;
        }

        return $buckets;
    }

    /**
     * Langkah 6b: buang stop terjauh dari centroid (prioritas terendah)
     * selama proyeksi waktu (visit + estimasi tempuh kasar, termasuk leg
     * hotel di kedua ujung) melebihi window harian.
     *
     * @return array{0: array<int, array<string, mixed>>, 1: array<int, array<string, mixed>>} [stops tersisa, stops yang di-overflow]
     */
    private function fitWithinBudget(array $stops, array $start, int $windowMinutes, ?array $centroid): array
    {
        $overflow = [];

        while ($stops !== [] && $this->projectedMinutes($stops, $start) > $windowMinutes) {
            $reference = $centroid ?? $start;
            usort($stops, fn ($a, $b) => Haversine::km($reference['lat'], $reference['lng'], $a['lat'], $a['lng'])
                <=> Haversine::km($reference['lat'], $reference['lng'], $b['lat'], $b['lng']));
            $overflow[] = array_pop($stops);
        }

        return [$stops, $overflow];
    }

    private function fillEmptySlots(array $stops, ?array $centroid, array $start, int $windowMinutes, Collection $candidatePool, Collection $usedPlaceIds): array
    {
        $reference = $centroid ?? $start;

        $available = $candidatePool
            ->filter(fn ($candidate) => ! $usedPlaceIds->has($candidate['places_id']))
            ->sortBy(fn ($candidate) => Haversine::km($reference['lat'], $reference['lng'], $candidate['lat'], $candidate['lng']))
            ->values();

        foreach ($available as $candidate) {
            $projected = array_merge($stops, [$candidate]);
            if ($this->projectedMinutes($projected, $start) > $windowMinutes) {
                break;
            }

            $stops[] = array_merge($candidate, ['wishlist_id' => null, 'source' => 'recommended']);
            $usedPlaceIds[$candidate['places_id']] = true;
        }

        return $stops;
    }

    /**
     * Estimasi kasar: visit duration semua stop + waktu tempuh Haversine
     * (detour x kecepatan kota) berurutan lewat rute NN sementara,
     * termasuk leg hotel->stop pertama dan stop terakhir->hotel.
     */
    private function projectedMinutes(array $stops, array $start): float
    {
        if ($stops === []) {
            return 0.0;
        }

        $keyed = [];
        foreach ($stops as $i => $stop) {
            $keyed[$i] = ['lat' => $stop['lat'], 'lng' => $stop['lng']];
        }
        $order = NearestNeighborRoute::order($start, $keyed);

        $visitMinutes = array_sum(array_column($stops, 'visit_minutes'));

        $travelMinutes = 0.0;
        $current = $start;
        foreach ($order as $key) {
            $travelMinutes += $this->legMinutes($current, $keyed[$key]);
            $current = $keyed[$key];
        }
        $travelMinutes += $this->legMinutes($current, $start);

        return $visitMinutes + $travelMinutes;
    }

    private function legMinutes(array $a, array $b): float
    {
        return Haversine::estimatedTravelMinutes($a['lat'], $a['lng'], $b['lat'], $b['lng'], self::DETOUR_FACTOR, self::AVERAGE_SPEED_KMH);
    }

    /**
     * F0010 (Swap, docs/prd design spec Section 7 langkah 7): urutan NN
     * dihitung ulang untuk SATU hari itu saja, polyline_to_here di-refresh
     * buat stop yang urutannya berubah - hari lain sama sekali tidak
     * disentuh. Tidak membuat/menghapus baris itinerary_items - places_id/
     * topsis_score/source item yang di-swap sudah diset oleh caller
     * sebelum method ini dipanggil, di sini cuma urutan + polyline.
     *
     * @return array{padat: bool}
     */
    public function resequenceDay(Trip $trip, ItineraryDay $day): array
    {
        $start = $trip->hotelCoordinates();
        $items = $day->items()->with('place')->get();

        $keyed = $items->mapWithKeys(fn (ItineraryItem $item) => [
            $item->itinerary_items_id => $item->coordinates(),
        ])->all();

        $order = $keyed === [] ? [] : NearestNeighborRoute::order($start, $keyed);

        $waypoints = array_merge([$start], array_map(fn ($key) => $keyed[$key], $order), [$start]);
        $legs = $order === [] ? [] : $this->routesClient->computeRoute($waypoints);

        $visitMinutesByItem = $items->keyBy('itinerary_items_id');

        foreach ($order as $i => $itemId) {
            $visitMinutesByItem[$itemId]->update([
                'visit_order' => $i + 1,
                'polyline_to_here' => $legs[$i]['polyline'] ?? null,
            ]);
        }

        $padat = false;
        if ($legs !== []) {
            $visitMinutes = $items->sum(fn (ItineraryItem $item) => $item->visitMinutes());
            $realMinutes = array_sum(array_column($legs, 'duration_seconds')) / 60 + $visitMinutes;
            $padat = $realMinutes > $this->windowMinutes($trip) * self::OVERBUDGET_THRESHOLD;
        }

        return ['padat' => $padat];
    }

    private function persistDay(Trip $trip, int $dayNumber, array $day, array $start): array
    {
        $stops = $day['stops'];

        $order = $stops === [] ? [] : NearestNeighborRoute::order(
            $start,
            collect($stops)->mapWithKeys(fn ($stop, $i) => [$i => ['lat' => $stop['lat'], 'lng' => $stop['lng']]])->all()
        );

        $orderedStops = array_map(fn ($key) => $stops[$key], $order);

        $itineraryDay = ItineraryDay::create([
            'trips_id' => $trip->trips_id,
            'day_number' => $dayNumber,
            'start_places_id' => $trip->hotel_places_id,
            'end_places_id' => $trip->hotel_places_id,
        ]);

        $waypoints = array_merge([$start], array_map(fn ($s) => ['lat' => $s['lat'], 'lng' => $s['lng']], $orderedStops), [$start]);

        $legs = $orderedStops === [] ? [] : $this->routesClient->computeRoute($waypoints);

        $items = [];
        foreach ($orderedStops as $i => $stop) {
            $items[] = ItineraryItem::create([
                'itinerary_days_id' => $itineraryDay->itinerary_days_id,
                'places_id' => $stop['places_id'],
                'visit_order' => $i + 1,
                'topsis_score' => $stop['topsis_score'],
                'source' => $stop['source'],
                'polyline_to_here' => $legs[$i]['polyline'] ?? null,
                ...($stop['places_id'] === null ? [
                    'custom_name' => $stop['label'],
                    'custom_lat' => $stop['lat'],
                    'custom_lng' => $stop['lng'],
                    'custom_visit_minutes' => $stop['visit_minutes'],
                ] : []),
            ]);
        }

        $padat = false;
        if ($legs !== []) {
            $realMinutes = array_sum(array_column($legs, 'duration_seconds')) / 60
                + array_sum(array_column($orderedStops, 'visit_minutes'));
            $padat = $realMinutes > $this->windowMinutes($trip) * self::OVERBUDGET_THRESHOLD;
        }

        return [
            'day' => $itineraryDay->setRelation('items', collect($items)),
            'tidak_muat' => $day['tidak_muat'],
            'padat' => $padat,
        ];
    }
}
