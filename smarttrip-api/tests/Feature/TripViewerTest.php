<?php

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TripViewerTest extends TestCase
{
    use RefreshDatabase;

    private function authHeader(User $user): array
    {
        return ['Authorization' => 'Bearer '.$user->createToken('test')->plainTextToken];
    }

    private function makeTrip(User $owner, array $overrides = []): Trip
    {
        return Trip::create(array_merge([
            'users_id' => $owner->users_id, 'title' => 'Trip', 'num_days' => 2,
            'budget_total' => 500000, 'start_date' => now()->addWeek()->toDateString(),
        ], $overrides));
    }

    // --- POST /api/trips/{id}/viewers (invite by email) ---

    public function test_the_owner_can_invite_a_registered_user_by_email(): void
    {
        $owner = User::factory()->create();
        $invitee = User::factory()->create(['email' => 'teman@test.com']);
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))
            ->postJson("/api/trips/{$trip->trips_id}/viewers", ['email' => 'teman@test.com']);

        $response->assertCreated();
        $this->assertDatabaseHas('trip_viewers', ['trips_id' => $trip->trips_id, 'users_id' => $invitee->users_id]);
    }

    public function test_inviting_an_unregistered_email_is_rejected_with_a_clear_error(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))
            ->postJson("/api/trips/{$trip->trips_id}/viewers", ['email' => 'tidakada@test.com']);

        $response->assertUnprocessable();
        $this->assertDatabaseMissing('trip_viewers', ['trips_id' => $trip->trips_id]);
    }

    public function test_the_owner_cannot_invite_themselves(): void
    {
        $owner = User::factory()->create(['email' => 'owner@test.com']);
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))
            ->postJson("/api/trips/{$trip->trips_id}/viewers", ['email' => 'owner@test.com']);

        $response->assertUnprocessable();
    }

    public function test_inviting_the_same_viewer_twice_is_a_no_op(): void
    {
        $owner = User::factory()->create();
        $invitee = User::factory()->create(['email' => 'teman@test.com']);
        $trip = $this->makeTrip($owner);
        $headers = $this->authHeader($owner);

        $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/viewers", ['email' => 'teman@test.com'])->assertCreated();
        $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/viewers", ['email' => 'teman@test.com'])->assertCreated();

        $this->assertSame(1, $trip->viewers()->count());
    }

    public function test_a_non_owner_cannot_invite_a_viewer(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        User::factory()->create(['email' => 'teman@test.com']);
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->postJson("/api/trips/{$trip->trips_id}/viewers", ['email' => 'teman@test.com']);

        $response->assertForbidden();
    }

    // --- GET /api/trips/{id}/viewers ---

    public function test_the_owner_can_list_viewers(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create(['name' => 'Budi', 'email' => 'budi@test.com']);
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($owner))
            ->getJson("/api/trips/{$trip->trips_id}/viewers");

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Budi', $response->json('data.0.name'));
        $this->assertSame('budi@test.com', $response->json('data.0.email'));
    }

    public function test_a_non_owner_cannot_list_viewers(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->getJson("/api/trips/{$trip->trips_id}/viewers");

        $response->assertForbidden();
    }

    // --- DELETE /api/trips/{id}/viewers/{viewer_id} ---

    public function test_the_owner_can_revoke_a_viewers_access(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($owner))
            ->deleteJson("/api/trips/{$trip->trips_id}/viewers/{$viewer->users_id}");

        $response->assertOk();
        $this->assertDatabaseMissing('trip_viewers', ['trips_id' => $trip->trips_id, 'users_id' => $viewer->users_id]);
    }

    public function test_revoking_access_for_a_user_who_is_not_a_viewer_404s(): void
    {
        $owner = User::factory()->create();
        $notAViewer = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))
            ->deleteJson("/api/trips/{$trip->trips_id}/viewers/{$notAViewer->users_id}");

        $response->assertNotFound();
    }

    public function test_a_non_owner_cannot_revoke_a_viewers_access(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->deleteJson("/api/trips/{$trip->trips_id}/viewers/{$viewer->users_id}");

        $response->assertForbidden();
        $this->assertDatabaseHas('trip_viewers', ['trips_id' => $trip->trips_id, 'users_id' => $viewer->users_id]);
    }

    public function test_a_revoked_viewer_can_no_longer_read_the_trip(): void
    {
        // Sanctum::actingAs (bukan header Bearer) supaya ganti user di
        // tengah test ini tidak kena bug caching RequestGuard::user() lintas
        // request dalam satu test method (lihat catatan di fitur-fitur lain).
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        Sanctum::actingAs($owner);
        $this->deleteJson("/api/trips/{$trip->trips_id}/viewers/{$viewer->users_id}")->assertOk();

        Sanctum::actingAs($viewer);
        $response = $this->getJson("/api/trips/{$trip->trips_id}");

        $response->assertForbidden();
    }

    // --- POST /api/trips/{id}/viewer-invite-link ---

    public function test_the_owner_can_generate_an_invite_link_token(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))
            ->postJson("/api/trips/{$trip->trips_id}/viewer-invite-link");

        $response->assertOk();
        $this->assertNotNull($response->json('viewer_invite_token'));
        $this->assertSame($trip->fresh()->viewer_invite_token, $response->json('viewer_invite_token'));
    }

    public function test_generating_an_invite_link_twice_returns_the_same_token(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $headers = $this->authHeader($owner);

        $first = $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/viewer-invite-link")->json('viewer_invite_token');
        $second = $this->withHeaders($headers)->postJson("/api/trips/{$trip->trips_id}/viewer-invite-link")->json('viewer_invite_token');

        $this->assertSame($first, $second);
    }

    public function test_a_non_owner_cannot_generate_an_invite_link(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->postJson("/api/trips/{$trip->trips_id}/viewer-invite-link");

        $response->assertForbidden();
    }

    // --- DELETE /api/trips/{id}/viewer-invite-link ---

    public function test_the_owner_can_disable_the_invite_link(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'oldtoken123']);

        $response = $this->withHeaders($this->authHeader($owner))
            ->deleteJson("/api/trips/{$trip->trips_id}/viewer-invite-link");

        $response->assertOk();
        $this->assertNull($trip->fresh()->viewer_invite_token);
    }

    public function test_disabling_the_invite_link_does_not_revoke_viewers_who_already_joined(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'oldtoken123']);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $this->withHeaders($this->authHeader($owner))
            ->deleteJson("/api/trips/{$trip->trips_id}/viewer-invite-link")
            ->assertOk();

        $this->assertDatabaseHas('trip_viewers', ['trips_id' => $trip->trips_id, 'users_id' => $viewer->users_id]);
    }

    public function test_a_non_owner_cannot_disable_the_invite_link(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'oldtoken123']);

        $response = $this->withHeaders($this->authHeader($stranger))
            ->deleteJson("/api/trips/{$trip->trips_id}/viewer-invite-link");

        $response->assertForbidden();
        $this->assertSame('oldtoken123', $trip->fresh()->viewer_invite_token);
    }
}
