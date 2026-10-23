<?php

namespace App\Services\Itinerary;

use App\Models\ItineraryItem;
use App\Models\Place;
use App\Services\Places\OpeningHours;
use Carbon\Carbon;
use Illuminate\Support\Collection;

/**
 * docs/prd design spec Section 7 langkah 7 (Swap): "ambil alternatif
 * TOPSIS peringkat berikutnya yang belum dipakai (kategori & radius hari
 * yang sama)". Sama persis matriks 4-kriteria di langkah 5 (dipakai ulang
 * bobot trip), cuma referensi jarak dipindah dari hotel ke centroid
 * stop-stop LAIN di hari itu (radius hari ini) dan dibatasi ke `type`
 * tempat yang sedang diganti.
 */
class SwapCandidateFinder
{
    /**
     * @return Collection<int, array{place: Place, topsis_score: float}>
     */
    public function rankedCandidates(ItineraryItem $item): Collection
    {
        $day = $item->day;
        $trip = $day->trip;
        $start = $day->startPoint();

        $otherStops = $day->items()
            ->where('itinerary_items_id', '!=', $item->itinerary_items_id)
            ->with('place')
            ->get();

        $centroid = $otherStops->isNotEmpty()
            ? KMeans::centroid($otherStops->map(fn (ItineraryItem $otherStop) => $otherStop->coordinates())->all())
            : $start;

        $usedElsewhereInTrip = ItineraryItem::query()
            ->whereHas('day', fn ($dayQuery) => $dayQuery->where('trips_id', $trip->trips_id))
            ->whereNotNull('places_id')
            ->pluck('places_id')
            ->all();

        $candidates = Place::query()
            // A custom wishlist pin has no type; any sight or eatery can replace it.
            ->when(
                $item->place !== null,
                fn ($placeQuery) => $placeQuery->where('type', $item->place->type),
                fn ($placeQuery) => $placeQuery->whereIn('type', ['attraction', 'culinary'])
            )
            ->whereNotIn('places_id', $usedElsewhereInTrip)
            ->with('categories')
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->get();

        // Not a place that is closed on this day of the trip (unknown hours count as open).
        $weekday = Carbon::parse($trip->start_date)->addDays($day->day_number - 1)->dayOfWeekIso;
        $candidates = $candidates
            ->reject(fn (Place $candidate) => OpeningHours::isOpenOn($candidate->opening_hours, $weekday) === false)
            ->values();

        if ($candidates->isEmpty()) {
            return collect();
        }

        $tripCategoryIds = $trip->interestCategories()->pluck('categories.categories_id')->all();
        $costEstimator = new PlaceCostEstimator($candidates);
        $ratingEstimator = new PlaceRatingEstimator($candidates);

        $matrix = [];
        foreach ($candidates as $candidate) {
            $matrix[$candidate->places_id] = [
                'kategori' => JaccardSimilarity::of($tripCategoryIds, $candidate->categories->pluck('categories_id')->all()),
                'jarak' => Haversine::km($centroid['lat'], $centroid['lng'], (float) $candidate->lat, (float) $candidate->lng),
                'anggaran' => $costEstimator->estimate($candidate),
                'rating' => $ratingEstimator->estimate($candidate),
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

        return $candidates
            ->map(fn (Place $place) => ['place' => $place, 'topsis_score' => $scores[$place->places_id]])
            ->sortByDesc('topsis_score')
            ->values();
    }

    /**
     * Null kalau $newPlace bukan bagian dari pool yang pernah discoring
     * (mis. dari hasil cari manual, atau type-nya beda) - persis definisi
     * "topsis_score NULL = dipilih manual" di PRD, bukan flag dari client.
     */
    public function scoreFor(ItineraryItem $item, Place $newPlace): ?float
    {
        $match = $this->rankedCandidates($item)->firstWhere(fn ($candidate) => $candidate['place']->places_id === $newPlace->places_id);

        return $match['topsis_score'] ?? null;
    }
}
