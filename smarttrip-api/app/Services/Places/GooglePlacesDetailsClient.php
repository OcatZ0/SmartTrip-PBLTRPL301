<?php

namespace App\Services\Places;

use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * F019 (docs/prd design spec Section 3 fase 3 - Enrichment, Enterprise SKU
 * mahal, cuma buat candidate yang di-approve admin). Place Details (New) -
 * field lengkap (rating, jam buka, harga, foto, deskripsi), beda dari
 * Text Search murah di Discovery (F018/GooglePlacesDiscoveryClient) yang
 * cuma minta field dasar.
 */
class GooglePlacesDetailsClient
{
    private const FIELD_MASK = 'id,displayName,formattedAddress,location,types,rating,userRatingCount,'
        .'priceLevel,regularOpeningHours,photos,editorialSummary,internationalPhoneNumber,websiteUri,businessStatus';

    /**
     * @return array{
     *     name: string, address: string, lat: float, lng: float, types: array<int, string>,
     *     rating: float|null, review_count: int|null, price_level: string|null,
     *     opening_hours: array|null, description: string|null, phone: string|null,
     *     website: string|null, business_status: string, photo_reference: string|null,
     * }
     */
    public function fetch(string $googlePlaceId): array
    {
        $response = Http::withHeaders([
            'X-Goog-Api-Key' => config('services.google.places_api_key'),
            'X-Goog-FieldMask' => self::FIELD_MASK,
        ])->get("https://places.googleapis.com/v1/places/{$googlePlaceId}");

        if ($response->failed()) {
            throw new RuntimeException('Google Place Details gagal: '.$response->body());
        }

        $place = $response->json();

        return [
            'name' => $place['displayName']['text'] ?? '',
            'address' => $place['formattedAddress'] ?? '',
            'lat' => (float) ($place['location']['latitude'] ?? 0),
            'lng' => (float) ($place['location']['longitude'] ?? 0),
            'types' => $place['types'] ?? [],
            'rating' => isset($place['rating']) ? (float) $place['rating'] : null,
            'review_count' => $place['userRatingCount'] ?? null,
            'price_level' => $place['priceLevel'] ?? null,
            'opening_hours' => $place['regularOpeningHours'] ?? null,
            'description' => $place['editorialSummary']['text'] ?? null,
            'phone' => $place['internationalPhoneNumber'] ?? null,
            'website' => $place['websiteUri'] ?? null,
            'business_status' => strtolower($place['businessStatus'] ?? 'operational'),
            'photo_reference' => $place['photos'][0]['name'] ?? null,
        ];
    }

    /**
     * Photo (New) - butuh resource name dari fetch() di atas
     * (places/{id}/photos/{photo_reference}), bukan URL langsung. Balikin
     * raw bytes gambar, BUKAN URL Google (URL itu butuh API key ikut kalau
     * di-hotlink dari mobile - lihat catatan privasi key di Section 2).
     */
    public function downloadPhoto(string $photoReference, int $maxWidthPx = 800): string
    {
        $response = Http::get("https://places.googleapis.com/v1/{$photoReference}/media", [
            'key' => config('services.google.places_api_key'),
            'maxWidthPx' => $maxWidthPx,
        ]);

        if ($response->failed()) {
            throw new RuntimeException('Google Place Photo gagal: '.$response->body());
        }

        return $response->body();
    }
}
