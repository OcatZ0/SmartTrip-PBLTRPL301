<?php

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_site_root_opens_the_admin_login(): void
    {
        $this->get('/')->assertRedirect('/admin/login');
    }
}
