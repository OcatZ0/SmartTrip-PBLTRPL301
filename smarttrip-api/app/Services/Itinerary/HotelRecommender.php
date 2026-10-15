<?php

namespace App\Services\Itinerary;

use App\Models\Place;
use App\Models\Trip;
use Illuminate\Support\Collection;
use RuntimeException;

/**
 * docs/prd design spec Section 7 langkah 4: TOPSIS 3-kriteria (jarak,
 * anggaran, rating) khusus type=lodging - dipakai kalau trip belum punya
 * hotel sendiri. Bobot pakai ulang 3 dari 4 kolom weight_* trip (kategori
 * dibuang, sisanya dinormalisasi ulang).
 */
class HotelRecommender
{
    /**
     * @return Collection<int, array{place: Place, topsis_score: float}>
     */
    public function topThree(Trip $trip): Collection
    {
        $reference = $this->referencePoint($trip);

        $lodgings = Place::query()
            ->where('type', 'lodging')
            ->where('business_status', '!=', 'closed_permanently')
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->get();

        if ($lodgings->isEmpty()) {
            return collect();
        }

        $costEstimator = new PlaceCostEstimator($lodgings);
        $ratingEstimator = new PlaceRatingEstimator($lodgings);

        $matrix = [];
        foreach ($lodgings as $lodging) {
            $matrix[$lodging->places_id] = [
                'jarak' => Haversine::km($reference['lat'], $reference['lng'], (float) $lodging->lat, (float) $lodging->lng),
                'anggaran' => $costEstimator->estimate($lodging),
                'rating' => $ratingEstimator->estimate($lodging),
            ];
        }

        $weights = $this->renormalizedWeights($trip);
        $isBenefit = ['jarak' => false, 'anggaran' => false, 'rating' => true];

        $scores = Topsis::rank($matrix, $weights, $isBenefit);

        return $lodgings
            ->map(fn (Place $place) => ['place' => $place, 'topsis_score' => $scores[$place->places_id]])
            ->sortByDesc('topsis_score')
            ->take(3)
            ->values();
    }

    /**
     * @return array{lat: float, lng: float}
     */
    private function referencePoint(Trip $trip): array
    {
        $wishlistPoints = $trip->wishlistPlaces()->with('place')->get()->map(function ($item) {
            return $item->places_id !== null
                ? ['lat' => (float) $item->place->lat, 'lng' => (float) $item->place->lng]
                : ['lat' => (float) $item->custom_lat, 'lng' => (float) $item->custom_lng];
        });

        if ($wishlistPoints->isNotEmpty()) {
            return KMeans::centroid($wishlistPoints->all());
        }

        // Wishlist kosong: fallback ke centroid top-5 kandidat berskor
        // tinggi di kategori minat trip (rating desc sebagai tie-break,
        // PRD tidak merinci skor gabungan yang dipakai).
        $categoryIds = $trip->interestCategories()->pluck('categories.categories_id')->all();

        $candidates = Place::query()
            ->whereIn('type', ['attraction', 'culinary'])
            ->where('business_status', '!=', 'closed_permanently')
            ->when($categoryIds !== [], fn ($hotelQuery) => $hotelQuery->whereHas('categories', fn ($categoryQuery) => $categoryQuery->whereIn('categories.categories_id', $categoryIds)))
            ->orderByDesc('rating')
            ->limit(5)
            ->get();

        if ($candidates->isEmpty()) {
            $candidates = Place::query()
                ->whereIn('type', ['attraction', 'culinary'])
                ->where('business_status', '!=', 'closed_permanently')
                ->orderByDesc('rating')
                ->limit(5)
                ->get();
        }

        if ($candidates->isEmpty()) {
            throw new RuntimeException('Tidak ada data tempat sama sekali - tidak bisa hitung rekomendasi hotel.');
        }

        return KMeans::centroid($candidates->map(fn (Place $hotel) => ['lat' => (float) $hotel->lat, 'lng' => (float) $hotel->lng])->all());
    }

    /**
     * @return array{jarak: float, anggaran: float, rating: float}
     */
    private function renormalizedWeights(Trip $trip): array
    {
        $jarak = (float) $trip->weight_jarak;
        $anggaran = (float) $trip->weight_anggaran;
        $rating = (float) $trip->weight_rating;
        $sum = $jarak + $anggaran + $rating;

        if ($sum <= 0) {
            return ['jarak' => 1 / 3, 'anggaran' => 1 / 3, 'rating' => 1 / 3];
        }

        return ['jarak' => $jarak / $sum, 'anggaran' => $anggaran / $sum, 'rating' => $rating / $sum];
    }
}
