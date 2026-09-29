<?php

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SharedTripsTest extends TestCase
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

    // --- POST /api/trips/join-viewer/{token} ---

    public function test_a_logged_in_user_can_claim_viewer_access_via_the_invite_link(): void
    {
        $owner = User::factory()->create();
        $invitee = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'tok123']);

        $response = $this->withHeaders($this->authHeader($invitee))
            ->postJson('/api/trips/join-viewer/tok123');

        $response->assertOk();
        $this->assertDatabaseHas('trip_viewers', ['trips_id' => $trip->trips_id, 'users_id' => $invitee->users_id]);
    }

    public function test_joining_via_an_invalid_token_404s(): void
    {
        $user = User::factory()->create();

        $response = $this->withHeaders($this->authHeader($user))
            ->postJson('/api/trips/join-viewer/does-not-exist');

        $response->assertNotFound();
    }

    public function test_claiming_access_requires_authentication(): void
    {
        $owner = User::factory()->create();
        $this->makeTrip($owner, ['viewer_invite_token' => 'tok123']);

        $response = $this->postJson('/api/trips/join-viewer/tok123');

        $response->assertUnauthorized();
    }

    public function test_joining_twice_via_the_same_link_is_a_no_op(): void
    {
        $owner = User::factory()->create();
        $invitee = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'tok123']);
        $headers = $this->authHeader($invitee);

        $this->withHeaders($headers)->postJson('/api/trips/join-viewer/tok123')->assertOk();
        $this->withHeaders($headers)->postJson('/api/trips/join-viewer/tok123')->assertOk();

        $this->assertSame(1, $trip->viewers()->count());
    }

    public function test_the_owner_joining_their_own_link_does_not_add_them_as_a_viewer(): void
    {
        $owner = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'tok123']);

        $response = $this->withHeaders($this->authHeader($owner))
            ->postJson('/api/trips/join-viewer/tok123');

        $response->assertOk();
        $this->assertDatabaseMissing('trip_viewers', ['trips_id' => $trip->trips_id, 'users_id' => $owner->users_id]);
    }

    public function test_revoking_the_invite_link_prevents_new_joins_but_not_disabling_existing_viewers(): void
    {
        // Sanctum::actingAs - dua user beda (owner lalu invitee) dalam satu
        // test, hindari bug caching RequestGuard::user() lintas request.
        $owner = User::factory()->create();
        $lateInvitee = User::factory()->create();
        $trip = $this->makeTrip($owner, ['viewer_invite_token' => 'tok123']);

        Sanctum::actingAs($owner);
        $this->deleteJson("/api/trips/{$trip->trips_id}/viewer-invite-link")->assertOk();

        Sanctum::actingAs($lateInvitee);
        $response = $this->postJson('/api/trips/join-viewer/tok123');

        $response->assertNotFound();
    }

    // --- GET /api/trips/shared ---

    public function test_a_user_can_list_trips_shared_with_them(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner, ['title' => 'Trip Bareng']);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($viewer))->getJson('/api/trips/shared');

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertSame('Trip Bareng', $response->json('data.0.title'));
    }

    public function test_shared_trips_list_requires_authentication(): void
    {
        $response = $this->getJson('/api/trips/shared');

        $response->assertUnauthorized();
    }

    public function test_a_users_own_trips_do_not_appear_in_the_shared_list(): void
    {
        $owner = User::factory()->create();
        $this->makeTrip($owner);

        $response = $this->withHeaders($this->authHeader($owner))->getJson('/api/trips/shared');

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    public function test_a_trip_shared_with_someone_else_does_not_appear_in_my_shared_list(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $unrelatedUser = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        $response = $this->withHeaders($this->authHeader($unrelatedUser))->getJson('/api/trips/shared');

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }

    public function test_a_user_can_both_own_trips_and_be_a_viewer_on_others_without_conflict(): void
    {
        $user = User::factory()->create();
        $otherOwner = User::factory()->create();
        $this->makeTrip($user, ['title' => 'Trip Saya']);
        $sharedTrip = $this->makeTrip($otherOwner, ['title' => 'Trip Bareng']);
        $sharedTrip->viewers()->attach($user->users_id, ['added_at' => now()]);

        $headers = $this->authHeader($user);

        $ownList = $this->withHeaders($headers)->getJson('/api/trips')->json('data');
        $sharedList = $this->withHeaders($headers)->getJson('/api/trips/shared')->json('data');

        $this->assertCount(1, $ownList);
        $this->assertSame('Trip Saya', $ownList[0]['title']);
        $this->assertCount(1, $sharedList);
        $this->assertSame('Trip Bareng', $sharedList[0]['title']);
    }

    public function test_revoking_a_viewers_access_removes_the_trip_from_their_shared_list(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $trip = $this->makeTrip($owner);
        $trip->viewers()->attach($viewer->users_id, ['added_at' => now()]);

        Sanctum::actingAs($owner);
        $this->deleteJson("/api/trips/{$trip->trips_id}/viewers/{$viewer->users_id}")->assertOk();

        Sanctum::actingAs($viewer);
        $response = $this->getJson('/api/trips/shared');

        $response->assertOk();
        $this->assertCount(0, $response->json('data'));
    }
}
