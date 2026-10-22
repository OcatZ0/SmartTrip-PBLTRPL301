<?php

namespace Tests;

use App\Models\Trip;
use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // public/build is not in git, so @vite views must render without a manifest.
        $this->withoutVite();
    }

    /**
     * Every day of the trip starts at the same place, like POST /hotel does.
     *
     * @param  array<string, mixed>  $start  start_places_id, or start_custom_name + start_lat + start_lng
     */
    protected function setTripStart(Trip $trip, array $start): void
    {
        $trip->syncDays();
        $trip->days()->update($start);
    }
}
