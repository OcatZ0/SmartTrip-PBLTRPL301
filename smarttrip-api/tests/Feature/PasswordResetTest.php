<?php

namespace Tests\Feature;

use App\Mail\PasswordResetMail;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    // --- F004: ubah password saat sudah login ---

    public function test_a_user_can_change_their_password_when_they_know_the_current_one(): void
    {
        $user = User::factory()->create(['password' => bcrypt('oldpassword123')]);
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->putJson('/api/auth/password', [
                'current_password' => 'oldpassword123',
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ]);

        $response->assertOk();
        $this->postJson('/api/auth/login', [
            'email' => $user->email,
            'password' => 'newpassword123',
        ])->assertOk();
    }

    public function test_changing_password_fails_with_the_wrong_current_password(): void
    {
        $user = User::factory()->create(['password' => bcrypt('oldpassword123')]);
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->putJson('/api/auth/password', [
                'current_password' => 'wrong-password',
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ]);

        $response->assertUnprocessable();
    }

    public function test_a_google_only_user_can_set_a_password_without_a_current_password(): void
    {
        $user = User::factory()->create(['password' => null, 'google_id' => 'google-sub-1']);
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->putJson('/api/auth/password', [
                'password' => 'newpassword123',
                'password_confirmation' => 'newpassword123',
            ]);

        $response->assertOk();
        $this->assertNotNull($user->fresh()->password);
    }

    // --- F004: lupa password ---

    public function test_forgot_password_sends_a_reset_email_for_a_registered_user(): void
    {
        Mail::fake();
        User::factory()->create(['email' => 'wisatawan@example.com']);

        $response = $this->postJson('/api/auth/forgot-password', ['email' => 'wisatawan@example.com']);

        $response->assertOk();
        Mail::assertSent(PasswordResetMail::class);
    }

    public function test_forgot_password_gives_the_same_response_for_an_unregistered_email(): void
    {
        Mail::fake();

        $response = $this->postJson('/api/auth/forgot-password', ['email' => 'tidakterdaftar@example.com']);

        $response->assertOk();
        Mail::assertNotSent(PasswordResetMail::class);
    }

    public function test_clicking_the_reset_link_and_submitting_a_new_password_works(): void
    {
        Mail::fake();
        $user = User::factory()->create(['email' => 'wisatawan@example.com', 'password' => bcrypt('oldpassword123')]);

        $this->postJson('/api/auth/forgot-password', ['email' => 'wisatawan@example.com'])->assertOk();

        $url = null;
        Mail::assertSent(PasswordResetMail::class, function (PasswordResetMail $mail) use (&$url) {
            $url = $mail->resetUrl;

            return true;
        });

        $this->get($url)->assertOk();

        $query = [];
        parse_str(parse_url($url, PHP_URL_QUERY), $query);

        $this->post('/auth/reset-password', [
            'email' => $query['email'],
            'token' => $query['token'],
            'password' => 'brandnewpassword',
            'password_confirmation' => 'brandnewpassword',
        ])->assertOk();

        $this->postJson('/api/auth/login', [
            'email' => 'wisatawan@example.com',
            'password' => 'brandnewpassword',
        ])->assertOk();
    }

    public function test_reset_password_api_endpoint_rejects_an_invalid_token(): void
    {
        User::factory()->create(['email' => 'wisatawan@example.com']);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'wisatawan@example.com',
            'token' => 'not-a-real-token',
            'password' => 'brandnewpassword',
            'password_confirmation' => 'brandnewpassword',
        ]);

        $response->assertUnprocessable();
    }
}
