<?php

namespace App\Services\Itinerary;

use App\Models\ItineraryDay;
use App\Models\ItineraryItem;
use App\Models\Place;
use App\Models\Trip;
use App\Services\Places\OpeningHours;
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
     * Opening hours (tingkat 1, by weekday only): a recommended place is
     * never put on a day it is closed, a wishlist place on its closed day
     * moves to another trip day it is open, and one closed on every trip day
     * is left out and reported in closed_wishlist_places. Unknown hours count
     * as open.
     *
     * @return array{days: array<int, array{day: ItineraryDay, tidak_muat: bool, padat: bool}>, dropped_wishlist_places: array<int, string>, closed_wishlist_places: array<int, string>}
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

        // ISO weekday of every trip day (day 1 is start_date).
        $weekdays = [];
        for ($dayIndex = 0; $dayIndex < count($dayBuckets); $dayIndex++) {
            $weekdays[$dayIndex] = Carbon::parse($trip->start_date)->addDays($dayIndex)->dayOfWeekIso;
        }

        $closedLabels = [];
        $dayBuckets = $this->moveOffClosedDays($dayBuckets, $weekdays, $start, $closedLabels);

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
            // An overflowing stop goes to the next day it is open on.
            $tidakMuat = false;
            foreach ($overflow as $item) {
                $nextOpenDay = null;
                for ($laterDay = $dayNumber + 1; $laterDay < $dayCount; $laterDay++) {
                    if (! in_array($weekdays[$laterDay], $item['closed_weekdays'], true)) {
                        $nextOpenDay = $laterDay;
                        break;
                    }
                }

                if ($nextOpenDay !== null) {
                    $dayBuckets[$nextOpenDay]['stops'][] = $item;
                } else {
                    $tidakMuat = true;
                    $droppedLabels[] = $item['label'];
                }
            }

            $openCandidates = $candidatePool->reject(fn ($candidate) => in_array($weekdays[$dayNumber], $candidate['closed_weekdays'], true));
            $stops = $this->fillEmptySlots($stops, $centroid, $start, $windowMinutes, $openCandidates, $usedPlaceIds);

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

        return DB::transaction(function () use ($trip, $days, $start, $droppedLabels, $closedLabels) {
            $trip->days()->delete();

            $result = [];

            foreach ($days as $dayNumber => $day) {
                $result[] = $this->persistDay($trip, $dayNumber + 1, $day, $start);
            }

            return ['days' => $result, 'dropped_wishlist_places' => $droppedLabels, 'closed_wishlist_places' => $closedLabels];
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
                    'closed_weekdays' => OpeningHours::closedWeekdays($item->place->opening_hours),
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
                'closed_weekdays' => [],
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
            ->when($excludedIds !== [], fn ($placeQuery) => $placeQuery->whereNotIn('places_id', $excludedIds))
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
            'closed_weekdays' => OpeningHours::closedWeekdays($place->opening_hours),
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
        for ($dayIndex = 0; $dayIndex < $numDays; $dayIndex++) {
            $buckets[$dayIndex] = ['stops' => [], 'centroid' => null];
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
                fn ($stop) => ['lat' => $stop['lat'], 'lng' => $stop['lng']],
                $stops
            ));
            $dayNumber++;
        }

        return $buckets;
    }

    /**
     * Opening hours, tingkat 1: a wishlist stop clustered onto a day it is
     * closed moves to the open trip day whose centroid is nearest; with no
     * open trip day it is left out and its label added to $closedLabels.
     * Centroids are recomputed for the days that changed.
     *
     * @param  array<int, int>  $weekdays  ISO weekday per day index
     * @param  array<int, string>  $closedLabels
     */
    private function moveOffClosedDays(array $buckets, array $weekdays, array $start, array &$closedLabels): array
    {
        $changed = [];

        foreach ($buckets as $dayIndex => $bucket) {
            foreach ($bucket['stops'] as $stopIndex => $stop) {
                if (! in_array($weekdays[$dayIndex], $stop['closed_weekdays'], true)) {
                    continue;
                }

                unset($buckets[$dayIndex]['stops'][$stopIndex]);
                $changed[$dayIndex] = true;

                $target = null;
                $targetDistance = INF;
                foreach ($buckets as $otherIndex => $other) {
                    if ($otherIndex === $dayIndex || in_array($weekdays[$otherIndex], $stop['closed_weekdays'], true)) {
                        continue;
                    }
                    $reference = $other['centroid'] ?? $start;
                    $distance = Haversine::km($reference['lat'], $reference['lng'], $stop['lat'], $stop['lng']);
                    if ($distance < $targetDistance) {
                        [$target, $targetDistance] = [$otherIndex, $distance];
                    }
                }

                if ($target === null) {
                    $closedLabels[] = $stop['label'];

                    continue;
                }

                $buckets[$target]['stops'][] = $stop;
                $changed[$target] = true;
            }
        }

        foreach (array_keys($changed) as $dayIndex) {
            $stops = array_values($buckets[$dayIndex]['stops']);
            $buckets[$dayIndex]['stops'] = $stops;
            $buckets[$dayIndex]['centroid'] = $stops === [] ? null : KMeans::centroid(array_map(
                fn ($stop) => ['lat' => $stop['lat'], 'lng' => $stop['lng']],
                $stops
            ));
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
            usort($stops, fn ($left, $right) => Haversine::km($reference['lat'], $reference['lng'], $left['lat'], $left['lng'])
                <=> Haversine::km($reference['lat'], $reference['lng'], $right['lat'], $right['lng']));
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
        foreach ($stops as $stopIndex => $stop) {
            $keyed[$stopIndex] = ['lat' => $stop['lat'], 'lng' => $stop['lng']];
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

    private function legMinutes(array $from, array $to): float
    {
        return Haversine::estimatedTravelMinutes($from['lat'], $from['lng'], $to['lat'], $to['lng'], self::DETOUR_FACTOR, self::AVERAGE_SPEED_KMH);
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

        foreach ($order as $position => $itemId) {
            $visitMinutesByItem[$itemId]->update([
                'visit_order' => $position + 1,
                'polyline_to_here' => $legs[$position]['polyline'] ?? null,
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
            collect($stops)->mapWithKeys(fn ($stop, $stopIndex) => [$stopIndex => ['lat' => $stop['lat'], 'lng' => $stop['lng']]])->all()
        );

        $orderedStops = array_map(fn ($key) => $stops[$key], $order);

        $itineraryDay = ItineraryDay::create([
            'trips_id' => $trip->trips_id,
            'day_number' => $dayNumber,
            'start_places_id' => $trip->hotel_places_id,
            'end_places_id' => $trip->hotel_places_id,
        ]);

        $waypoints = array_merge([$start], array_map(fn ($stop) => ['lat' => $stop['lat'], 'lng' => $stop['lng']], $orderedStops), [$start]);

        $legs = $orderedStops === [] ? [] : $this->routesClient->computeRoute($waypoints);

        $items = [];
        foreach ($orderedStops as $position => $stop) {
            $items[] = ItineraryItem::create([
                'itinerary_days_id' => $itineraryDay->itinerary_days_id,
                'places_id' => $stop['places_id'],
                'visit_order' => $position + 1,
                'topsis_score' => $stop['topsis_score'],
                'source' => $stop['source'],
                'polyline_to_here' => $legs[$position]['polyline'] ?? null,
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
