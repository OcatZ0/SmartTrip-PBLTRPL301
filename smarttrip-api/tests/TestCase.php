<?php

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // public/build is not in git, so @vite views must render without a manifest.
        $this->withoutVite();
    }
}
