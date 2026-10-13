<?php

namespace Tests\Feature;

use App\Services\Itinerary\EncodedPolyline;
use App\Services\Itinerary\OpenRouteServiceClient;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use RuntimeException;
use Tests\TestCase;

class OpenRouteServiceClientTest extends TestCase
{
    public function test_it_sends_lng_lat_pairs_and_cuts_one_leg_per_segment(): void
    {
        config(['services.openrouteservice.api_key' => 'ors-test-key']);
        Http::fake([
            'api.openrouteservice.org/*' => Http::response(['features' => [[
                'geometry' => ['type' => 'LineString', 'coordinates' => [
                    [104.00, 1.10], [104.01, 1.11], [104.02, 1.12], [104.03, 1.13], [104.00, 1.10],
                ]],
                'properties' => [
                    'segments' => [['duration' => 300.4], ['duration' => 899.6]],
                    'way_points' => [0, 2, 4],
                ],
            ]]]),
        ]);

        $legs = (new OpenRouteServiceClient)->computeRoute([
            ['lat' => 1.10, 'lng' => 104.00],
            ['lat' => 1.12, 'lng' => 104.02],
            ['lat' => 1.10, 'lng' => 104.00],
        ]);

        Http::assertSent(fn (Request $request) => $request->hasHeader('Authorization', 'ors-test-key')
            && $request['coordinates'] === [[104.00, 1.10], [104.02, 1.12], [104.00, 1.10]]);

        $this->assertCount(2, $legs);
        $this->assertSame(300, $legs[0]['duration_seconds']);
        $this->assertSame(900, $legs[1]['duration_seconds']);
        $this->assertSame(EncodedPolyline::encode([
            ['lat' => 1.10, 'lng' => 104.00], ['lat' => 1.11, 'lng' => 104.01], ['lat' => 1.12, 'lng' => 104.02],
        ]), $legs[0]['polyline']);
        $this->assertSame(EncodedPolyline::encode([
            ['lat' => 1.12, 'lng' => 104.02], ['lat' => 1.13, 'lng' => 104.03], ['lat' => 1.10, 'lng' => 104.00],
        ]), $legs[1]['polyline']);
    }

    public function test_an_error_response_becomes_a_runtime_exception(): void
    {
        Http::fake(['api.openrouteservice.org/*' => Http::response(['error' => 'quota'], 403)]);

        $this->expectException(RuntimeException::class);

        (new OpenRouteServiceClient)->computeRoute([['lat' => 1.1, 'lng' => 104.0], ['lat' => 1.2, 'lng' => 104.1]]);
    }

    public function test_a_timeout_becomes_a_runtime_exception(): void
    {
        Http::fake(['api.openrouteservice.org/*' => fn () => throw new ConnectionException('timed out')]);

        $this->expectException(RuntimeException::class);

        (new OpenRouteServiceClient)->computeRoute([['lat' => 1.1, 'lng' => 104.0], ['lat' => 1.2, 'lng' => 104.1]]);
    }
}
