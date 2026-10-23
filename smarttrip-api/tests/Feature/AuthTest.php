<?php

namespace Tests\Feature;

use App\Mail\RegistrationVerificationMail;
use App\Models\User;
use Illuminate\Database\QueryException;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function fakeGoogleToken(string $email, string $sub, array $overrides = []): void
    {
        config(['services.google.client_id' => 'test-client-id']);

        Http::fake([
            'oauth2.googleapis.com/*' => Http::response(array_merge([
                'aud' => 'test-client-id',
                'sub' => $sub,
                'email' => $email,
                'email_verified' => 'true',
                'name' => 'Wisatawan Google',
            ], $overrides)),
        ]);
    }

    private function captureVerificationUrl(string $email, string $password): string
    {
        Mail::fake();

        $this->postJson('/api/auth/register', [
            'name' => 'Wisatawan Test',
            'email' => $email,
            'password' => $password,
            'password_confirmation' => $password,
        ])->assertAccepted();

        $url = null;
        Mail::assertSent(RegistrationVerificationMail::class, function (RegistrationVerificationMail $mail) use (&$url) {
            $url = $mail->verificationUrl;

            return true;
        });

        return $url;
    }

    public function test_registering_does_not_create_a_user_until_verified(): void
    {
        Mail::fake();

        $response = $this->postJson('/api/auth/register', [
            'name' => 'Wisatawan Test',
            'email' => 'wisatawan@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertAccepted();
        $this->assertDatabaseMissing('users', ['email' => 'wisatawan@example.com']);
        $this->assertDatabaseHas('pending_registrations', ['email' => 'wisatawan@example.com']);
        Mail::assertSent(RegistrationVerificationMail::class);
    }

    public function test_clicking_the_verification_link_creates_and_verifies_the_user(): void
    {
        $url = $this->captureVerificationUrl('wisatawan@example.com', 'password123');

        $response = $this->get($url);

        $response->assertOk();
        $this->assertDatabaseHas('users', ['email' => 'wisatawan@example.com']);
        $this->assertDatabaseMissing('pending_registrations', ['email' => 'wisatawan@example.com']);

        $user = User::where('email', 'wisatawan@example.com')->first();
        $this->assertNotNull($user->email_verified_at);

        $this->postJson('/api/auth/login', [
            'email' => 'wisatawan@example.com',
            'password' => 'password123',
        ])->assertOk();
    }

    public function test_a_verification_link_older_than_60_minutes_says_it_expired_and_drops_the_registration(): void
    {
        $url = $this->captureVerificationUrl('wisatawan@example.com', 'password123');

        $this->travel(61)->minutes();
        $response = $this->get($url);

        $response->assertOk()->assertSee('Tautan verifikasi sudah kedaluwarsa. Silakan daftar ulang.');
        $this->assertDatabaseMissing('users', ['email' => 'wisatawan@example.com']);
        $this->assertDatabaseMissing('pending_registrations', ['email' => 'wisatawan@example.com']);
    }

    public function test_a_verification_link_with_a_wrong_token_says_it_is_invalid(): void
    {
        $url = $this->captureVerificationUrl('wisatawan@example.com', 'password123');

        $response = $this->get(preg_replace('/token=[^&]+/', 'token=wrong', $url));

        $response->assertOk()->assertSee('Tautan verifikasi tidak valid.');
        $this->assertDatabaseMissing('users', ['email' => 'wisatawan@example.com']);
        $this->assertDatabaseHas('pending_registrations', ['email' => 'wisatawan@example.com']);
    }

    public function test_registering_with_an_email_already_taken_by_a_password_account_is_rejected(): void
    {
        User::factory()->create(['email' => 'wisatawan@example.com']);

        $response = $this->postJson('/api/auth/register', [
            'name' => 'Wisatawan Test',
            'email' => 'wisatawan@example.com',
            'password' => 'password123',
            'password_confirmation' => 'password123',
        ]);

        $response->assertUnprocessable();
    }

    public function test_a_user_can_login_with_correct_credentials(): void
    {
        User::factory()->create([
            'email' => 'wisatawan@example.com',
            'password' => bcrypt('password123'),
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'wisatawan@example.com',
            'password' => 'password123',
        ]);

        $response->assertOk()->assertJsonStructure(['user', 'token']);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create(['email' => 'wisatawan@example.com']);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'wisatawan@example.com',
            'password' => 'wrong-password',
        ]);

        $response->assertUnprocessable();
    }

    public function test_an_authenticated_user_can_logout(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        $response = $this->withHeader('Authorization', "Bearer $token")
            ->postJson('/api/auth/logout');

        $response->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_admin_only_dashboard_rejects_a_regular_user(): void
    {
        $user = User::factory()->create(['role' => 'user']);

        $response = $this->actingAs($user)->get('/admin/dashboard');

        $response->assertForbidden();
    }

    public function test_admin_can_view_the_dashboard(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);

        $response = $this->actingAs($admin)->get('/admin/dashboard');

        $response->assertOk();
    }

    public function test_deleting_a_user_is_a_soft_delete(): void
    {
        $user = User::factory()->create();

        $user->delete();

        $this->assertSoftDeleted($user);
        $this->assertDatabaseHas('users', ['users_id' => $user->users_id]);
    }

    public function test_a_soft_deleted_users_email_and_google_id_can_be_reused(): void
    {
        $old = User::factory()->create(['email' => 'budi@example.com', 'google_id' => 'google-sub-budi']);
        $old->delete();

        $new = User::factory()->create(['email' => 'budi@example.com', 'google_id' => 'google-sub-budi']);

        $this->assertNotSame($old->users_id, $new->users_id);
        $this->assertSame(1, User::where('email', 'budi@example.com')->count());
        $this->assertSame($new->users_id, User::where('google_id', 'google-sub-budi')->value('users_id'));
    }

    public function test_two_active_users_cannot_share_an_email(): void
    {
        User::factory()->create(['email' => 'budi@example.com']);

        $this->expectException(QueryException::class);

        User::factory()->create(['email' => 'budi@example.com']);
    }

    public function test_two_active_users_cannot_share_a_google_id(): void
    {
        User::factory()->create(['google_id' => 'google-sub-budi']);

        $this->expectException(QueryException::class);

        User::factory()->create(['google_id' => 'google-sub-budi']);
    }

    // --- Google Sign-In + account linking scenarios ---

    public function test_google_login_creates_a_new_user_when_email_is_unregistered(): void
    {
        $this->fakeGoogleToken('baru@example.com', 'google-sub-1');

        $response = $this->postJson('/api/auth/google', ['id_token' => 'fake-token']);

        $response->assertOk()->assertJsonStructure(['user', 'token']);
        $user = User::where('email', 'baru@example.com')->first();
        $this->assertNotNull($user);
        $this->assertSame('google-sub-1', $user->google_id);
        $this->assertNull($user->password);
        $this->assertNotNull($user->email_verified_at);
    }

    public function test_the_user_json_says_whether_the_account_has_a_password(): void
    {
        $googleOnly = User::factory()->create(['password' => null, 'google_id' => 'google-sub-9']);
        $withPassword = User::factory()->create();

        $this->actingAs($googleOnly)->getJson('/api/user')->assertOk()->assertJsonPath('has_password', false);
        $this->actingAs($withPassword)->getJson('/api/user')->assertOk()->assertJsonPath('has_password', true);
    }

    public function test_a_google_only_account_sets_its_first_password_without_a_current_one(): void
    {
        $user = User::factory()->create(['password' => null, 'google_id' => 'google-sub-10']);

        $this->actingAs($user)->putJson('/api/auth/password', [
            'password' => 'passwordbaru1',
            'password_confirmation' => 'passwordbaru1',
        ])->assertOk();

        $this->assertTrue($user->fresh()->has_password);
    }

    public function test_password_login_fails_for_a_google_only_account(): void
    {
        User::factory()->create([
            'email' => 'googleuser@example.com',
            'password' => null,
            'google_id' => 'google-sub-2',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'email' => 'googleuser@example.com',
            'password' => 'anything123',
        ]);

        $response->assertUnprocessable();
    }

    public function test_registering_after_google_login_links_password_to_the_existing_account(): void
    {
        User::factory()->create([
            'email' => 'googleuser@example.com',
            'password' => null,
            'google_id' => 'google-sub-3',
        ]);

        $url = $this->captureVerificationUrl('googleuser@example.com', 'newpassword123');

        $this->get($url)->assertOk();

        $this->assertDatabaseCount('users', 1);
        $user = User::where('email', 'googleuser@example.com')->first();
        $this->assertNotNull($user->password);
        $this->assertSame('google-sub-3', $user->google_id);

        $this->postJson('/api/auth/login', [
            'email' => 'googleuser@example.com',
            'password' => 'newpassword123',
        ])->assertOk();
    }

    public function test_google_login_links_to_an_existing_verified_manual_account_without_extra_verification(): void
    {
        User::factory()->create([
            'email' => 'manual@example.com',
            'password' => bcrypt('password123'),
            'email_verified_at' => now(),
            'google_id' => null,
        ]);

        $this->fakeGoogleToken('manual@example.com', 'google-sub-4');

        $response = $this->postJson('/api/auth/google', ['id_token' => 'fake-token']);

        $response->assertOk();
        $this->assertDatabaseCount('users', 1);
        $user = User::where('email', 'manual@example.com')->first();
        $this->assertSame('google-sub-4', $user->google_id);
    }
}
