<?php

namespace App\Services\Places;

use App\Models\Place;
use App\Models\PlaceCandidate;
use App\Services\Itinerary\Haversine;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

/**
 * The same real place does not always come back under the same id: a place
 * entered by hand has none, and OpenStreetMap often maps one venue twice (a
 * node for the entrance and a way for the building). So besides the id, two
 * records count as one place when one name contains the other as whole words
 * ("Ocarina" and "Pantai Ocarina") and they are at most 100 m apart.
 */
class PlaceDuplicateFinder
{
    public const RADIUS_METERS = 100;

    // Pre-filter box before the exact distance: 0.001 degree is about 111 m
    // near the equator, Batam sits at 1 degree north.
    private const BOX_DEGREES = 0.001;

    /**
     * Soft-deleted places count too, so a place the admin removed does not
     * come back through Discovery.
     */
    public function findPlace(?string $externalPlaceId, string $name, float $lat, float $lng): ?Place
    {
        return $this->find(Place::withTrashed(), $externalPlaceId, $name, $lat, $lng);
    }

    /**
     * Candidates in any status, so a rejected one never resurfaces.
     * [olderThanId] limits the search to earlier candidates, letting a
     * cleanup keep the first of a duplicate pair.
     */
    public function findCandidate(
        ?string $externalPlaceId,
        string $name,
        float $lat,
        float $lng,
        ?int $olderThanId = null,
    ): ?PlaceCandidate {
        $query = PlaceCandidate::query()
            ->when($olderThanId !== null, fn (Builder $q) => $q->where('place_candidates_id', '<', $olderThanId));

        return $this->find($query, $externalPlaceId, $name, $lat, $lng);
    }

    private function find(Builder $query, ?string $externalPlaceId, string $name, float $lat, float $lng): ?Model
    {
        if ($externalPlaceId !== null) {
            $sameId = (clone $query)->where('external_place_id', $externalPlaceId)->first();
            if ($sameId !== null) {
                return $sameId;
            }
        }

        return $query
            ->whereBetween('lat', [$lat - self::BOX_DEGREES, $lat + self::BOX_DEGREES])
            ->whereBetween('lng', [$lng - self::BOX_DEGREES, $lng + self::BOX_DEGREES])
            ->get()
            ->first(fn (Model $other) => $this->sameName($name, $other->name)
                && Haversine::km($lat, $lng, (float) $other->lat, (float) $other->lng) * 1000 <= self::RADIUS_METERS);
    }

    private function sameName(string $a, string $b): bool
    {
        $a = $this->normalize($a);
        $b = $this->normalize($b);

        if ($a === '' || $b === '') {
            return false;
        }

        return str_contains(" {$a} ", " {$b} ") || str_contains(" {$b} ", " {$a} ");
    }

    private function normalize(string $name): string
    {
        return trim(preg_replace('/[^a-z0-9]+/', ' ', Str::lower(Str::ascii($name))));
    }
}
