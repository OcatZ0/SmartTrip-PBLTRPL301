<?php

namespace App\Services\Places;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * F018 (docs/prd design spec Section 3 fase 1 - Discovery, Pro SKU murah).
 * Text Search (New) - cuma minta field dasar (id, nama, lokasi, tipe),
 * BUKAN Place Details (Enterprise SKU, itu di fase Enrichment/F020).
 */
class GooglePlacesDiscoveryClient
{
    /**
     * @return array<int, array{google_place_id: string, name: string, lat: float, lng: float, types: array<int, string>}>
     */
    public function textSearch(string $query): array
    {
        $response = Http::withHeaders([
            'Content-Type' => 'application/json',
            'X-Goog-Api-Key' => config('services.google.places_api_key'),
            'X-Goog-FieldMask' => 'places.id,places.displayName,places.location,places.types',
        ])->post('https://places.googleapis.com/v1/places:searchText', [
            'textQuery' => $query,
            'languageCode' => 'id',
        ]);

        if ($response->failed()) {
            throw new RuntimeException('Google Places Text Search gagal: '.$response->body());
        }

        $places = $response->json('places', []);

        return array_map(fn (array $place) => [
            'google_place_id' => $place['id'],
            'name' => $place['displayName']['text'] ?? '',
            'lat' => (float) ($place['location']['latitude'] ?? 0),
            'lng' => (float) ($place['location']['longitude'] ?? 0),
            'types' => $place['types'] ?? [],
        ], $places);
    }
}
