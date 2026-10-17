<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminLoginTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::factory()->create(['role' => 'admin', 'password' => 'rahasia-123']);
    }

    public function test_the_login_page_plays_the_opening_on_a_fresh_visit(): void
    {
        $this->get(route('admin.login'))
            ->assertOk()
            ->assertSee('text-white auth-intro"', false)
            ->assertSee('id="loginForm"', false);
    }

    public function test_a_form_post_still_redirects_to_the_dashboard(): void
    {
        $this->post(route('admin.login.attempt'), ['email' => $this->admin->email, 'password' => 'rahasia-123'])
            ->assertRedirect(route('admin.dashboard'));

        $this->assertAuthenticatedAs($this->admin);
    }

    public function test_the_fetch_login_gets_the_dashboard_url_as_json(): void
    {
        $this->postJson(route('admin.login.attempt'), ['email' => $this->admin->email, 'password' => 'rahasia-123'])
            ->assertOk()
            ->assertExactJson(['redirect' => route('admin.dashboard')]);

        $this->assertAuthenticatedAs($this->admin);
    }

    public function test_a_wrong_password_comes_back_as_a_422_for_fetch(): void
    {
        $this->postJson(route('admin.login.attempt'), ['email' => $this->admin->email, 'password' => 'salah'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.email.0', 'Email atau kata sandi salah.');

        $this->assertGuest();
    }

    public function test_a_non_admin_is_refused_for_fetch_too(): void
    {
        $traveler = User::factory()->create(['role' => 'user', 'password' => 'rahasia-123']);

        $this->postJson(route('admin.login.attempt'), ['email' => $traveler->email, 'password' => 'rahasia-123'])
            ->assertUnprocessable()
            ->assertJsonPath('errors.email.0', 'Akun ini bukan akun admin.');

        $this->assertGuest();
    }

    public function test_a_failed_form_post_skips_the_opening(): void
    {
        $this->from(route('admin.login'))
            ->followingRedirects()
            ->post(route('admin.login.attempt'), ['email' => $this->admin->email, 'password' => 'salah'])
            ->assertOk()
            ->assertDontSee('text-white auth-intro"', false)
            ->assertSee('Email atau kata sandi salah.');
    }
}
