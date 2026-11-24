<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class EmailJsTest extends TestCase
{
    use RefreshDatabase;

    private const ENDPOINT = 'https://api.emailjs.com/api/v1.0/email/send';

    protected function setUp(): void
    {
        parent::setUp();

        config(['services.emailjs' => [
            'service_id' => 'service_test',
            'template_id' => 'template_test',
            'public_key' => 'public_test',
            'private_key' => 'private_test',
        ]]);
        Mail::fake();
    }

    public function test_the_reset_link_goes_through_emailjs_with_the_template_params(): void
    {
        Http::fake([self::ENDPOINT => Http::response('OK')]);
        User::factory()->create(['email' => 'wisatawan@example.com']);

        $this->postJson('/api/auth/forgot-password', ['email' => 'wisatawan@example.com'])->assertOk();

        Http::assertSent(function (Request $request) {
            $params = $request['template_params'];

            return $request->url() === self::ENDPOINT
                && $request['service_id'] === 'service_test'
                && $request['template_id'] === 'template_test'
                && $request['user_id'] === 'public_test'
                && $request['accessToken'] === 'private_test'
                && $params['to_email'] === 'wisatawan@example.com'
                && $params['subject'] === 'Atur Ulang Kata Sandi - SmartTrip'
                && str_contains($params['action_url'], '/auth/reset-password?')
                && str_contains($params['action_url'], 'token=');
        });
        Mail::assertNothingSent();
    }

    public function test_a_failed_reset_email_does_not_reveal_that_the_account_exists(): void
    {
        Http::fake([self::ENDPOINT => Http::response('The service is not allowed', 403)]);
        User::factory()->create(['email' => 'wisatawan@example.com']);

        $known = $this->postJson('/api/auth/forgot-password', ['email' => 'wisatawan@example.com']);
        $unknown = $this->postJson('/api/auth/forgot-password', ['email' => 'lain@example.com']);

        $known->assertOk();
        $unknown->assertOk();
        $this->assertSame($unknown->json('message'), $known->json('message'));
    }

    public function test_registration_reports_when_the_verification_email_could_not_be_sent(): void
    {
        Http::fake([self::ENDPOINT => Http::response('Bad request', 400)]);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'Wisatawan Test',
            'email' => 'baru@example.com',
            'password' => 'rahasia123',
            'password_confirmation' => 'rahasia123',
        ]);

        $response->assertStatus(503);
        $this->assertStringContainsString('gagal dikirim', $response->json('message'));
    }

    public function test_registration_sends_the_verification_link_through_emailjs(): void
    {
        Http::fake([self::ENDPOINT => Http::response('OK')]);

        $this->postJson('/api/auth/register', [
            'name' => 'Wisatawan Test',
            'email' => 'baru@example.com',
            'password' => 'rahasia123',
            'password_confirmation' => 'rahasia123',
        ])->assertAccepted();

        Http::assertSent(fn (Request $request) => $request['template_params']['subject'] === 'Verifikasi Akun SmartTrip'
            && str_contains($request['template_params']['action_url'], '/auth/verify-registration?')
            && str_contains($request['template_params']['message'], 'Wisatawan Test'));
        Mail::assertNothingSent();
    }
}
