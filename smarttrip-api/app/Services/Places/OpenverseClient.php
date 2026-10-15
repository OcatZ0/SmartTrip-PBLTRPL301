<?php

namespace App\Services\Places;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Openverse (by WordPress, formerly CC Search): Creative Commons and public
 * domain images from Flickr, Wikimedia Commons and others. Free and keyless
 * for low volume. Used by the admin to find a real, openly licensed photo of
 * a place; Geoapify has no photos and Google Places needs billing.
 *
 * Search results need a human check: a name search can return unrelated
 * pictures, so nothing is attached without the admin picking it.
 */
class OpenverseClient
{
    private const IMAGES_URL = 'https://api.openverse.org/v1/images/';

    private const TIMEOUT_SECONDS = 20;

    /**
     * Wikimedia, where many Openverse images live, throttles requests whose
     * User-Agent has no way to contact the operator.
     */
    public const USER_AGENT = 'SmartTripBatam/1.0 (+https://github.com/OcatZ0/SmartTrip-PBLTRPL301)';

    public const PAGE_SIZE = 12;

    /**
     * @return array<int, array<string, mixed>> see [normalize]
     */
    public function search(string $query): array
    {
        $response = $this->get(self::IMAGES_URL, ['q' => $query, 'page_size' => self::PAGE_SIZE]);

        return array_map(fn (array $image) => $this->normalize($image), $response->json('results', []));
    }

    /**
     * One image's metadata straight from Openverse, so the license and credit
     * saved with a photo never come from the browser.
     *
     * @return array<string, mixed> see [normalize]
     */
    public function find(string $id): array
    {
        if (! preg_match('/^[0-9a-f-]{36}$/i', $id)) {
            throw new RuntimeException('ID foto Openverse tidak valid.');
        }

        return $this->normalize($this->get(self::IMAGES_URL.$id.'/', [])->json());
    }

    /**
     * @return array{id: string, title: string, creator: string|null, license: string, license_url: string|null,
     *     source_url: string|null, url: string, thumbnail: string|null, provider: string|null, commercial: bool}
     */
    private function normalize(array $image): array
    {
        $code = strtolower((string) ($image['license'] ?? ''));

        return [
            'id' => (string) ($image['id'] ?? ''),
            'title' => (string) ($image['title'] ?? ''),
            'creator' => $image['creator'] ?? null,
            'license' => $this->licenseLabel($code, (string) ($image['license_version'] ?? '')),
            'license_url' => $image['license_url'] ?? null,
            'source_url' => $image['foreign_landing_url'] ?? null,
            'url' => (string) ($image['url'] ?? ''),
            'thumbnail' => $image['thumbnail'] ?? null,
            'provider' => $image['provider'] ?? ($image['source'] ?? null),
            // NC licenses only allow non-commercial use.
            'commercial' => ! str_contains($code, 'nc'),
        ];
    }

    private function licenseLabel(string $code, string $version): string
    {
        return match ($code) {
            'cc0' => 'CC0 '.($version ?: '1.0'),
            'pdm' => 'Public Domain',
            default => trim('CC '.strtoupper($code).' '.$version),
        };
    }

    private function get(string $url, array $query): Response
    {
        try {
            $response = Http::timeout(self::TIMEOUT_SECONDS)
                ->withHeaders(['User-Agent' => self::USER_AGENT])
                ->get($url, $query);
        } catch (ConnectionException $exception) {
            throw new RuntimeException('Openverse tidak bisa dihubungi: '.$exception->getMessage(), 0, $exception);
        }

        if ($response->failed()) {
            throw new RuntimeException('Openverse gagal ('.$response->status().').');
        }

        return $response;
    }
}
