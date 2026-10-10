<?php

namespace App\Services\Itinerary;

use App\Models\ItineraryItem;
use App\Models\Place;
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
        $start = $trip->hotelCoordinates();

        $otherStops = $day->items()
            ->where('itinerary_items_id', '!=', $item->itinerary_items_id)
            ->with('place')
            ->get()
            ->filter(fn (ItineraryItem $i) => $i->place !== null);

        $centroid = $otherStops->isNotEmpty()
            ? KMeans::centroid($otherStops->map(fn (ItineraryItem $i) => [
                'lat' => (float) $i->place->lat, 'lng' => (float) $i->place->lng,
            ])->all())
            : $start;

        $usedElsewhereInTrip = ItineraryItem::query()
            ->whereHas('day', fn ($q) => $q->where('trips_id', $trip->trips_id))
            ->whereNotNull('places_id')
            ->pluck('places_id')
            ->all();

        $candidates = Place::query()
            ->where('type', $item->place->type)
            ->where('business_status', '!=', 'closed_permanently')
            ->whereNotIn('places_id', $usedElsewhereInTrip)
            ->with('categories')
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->get();

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
        $match = $this->rankedCandidates($item)->firstWhere(fn ($c) => $c['place']->places_id === $newPlace->places_id);

        return $match['topsis_score'] ?? null;
    }
}
