<?php

namespace Tests\Feature;

use App\Jobs\RunPlaceDiscovery;
use App\Models\DiscoveryRun;
use App\Models\User;
use App\Services\Places\PlaceDiscoveryService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class DiscoveryRunTest extends TestCase
{
    use RefreshDatabase;

    private User $admin;

    protected function setUp(): void
    {
        parent::setUp();

        $this->admin = User::factory()->create(['role' => 'admin', 'name' => 'Admin Satu']);
    }

    public function test_starting_discovery_queues_a_run_and_answers_right_away(): void
    {
        Queue::fake();

        $response = $this->actingAs($this->admin)->postJson(route('admin.candidates.discover'));

        $response->assertStatus(202)
            ->assertJsonPath('run.status', 'queued')
            ->assertJsonPath('run.total_steps', PlaceDiscoveryService::stepCount())
            ->assertJsonPath('run.started_by', 'Admin Satu');
        Queue::assertPushed(RunPlaceDiscovery::class, fn (RunPlaceDiscovery $job) => $job->run->is(DiscoveryRun::sole()));
    }

    public function test_a_second_run_is_refused_while_one_is_active(): void
    {
        Queue::fake();
        DiscoveryRun::create(['status' => 'running', 'total_steps' => 36, 'done_steps' => 5]);

        $this->actingAs($this->admin)->postJson(route('admin.candidates.discover'))
            ->assertStatus(409)
            ->assertJsonPath('run.done_steps', 5);

        Queue::assertNothingPushed();
        $this->assertSame(1, DiscoveryRun::count());
    }

    public function test_a_stale_run_no_longer_blocks_discovery(): void
    {
        Queue::fake();
        $stale = DiscoveryRun::create(['status' => 'queued', 'total_steps' => 36]);
        DiscoveryRun::whereKey($stale->getKey())->update(['updated_at' => now()->subMinutes(20)]);

        $this->actingAs($this->admin)->postJson(route('admin.candidates.discover'))->assertStatus(202);

        $this->assertSame('failed', $stale->fresh()->status);
        $this->assertStringContainsString('Worker queue tidak mengambil', $stale->fresh()->error);
        Queue::assertPushed(RunPlaceDiscovery::class);
    }

    public function test_the_job_records_progress_for_every_search(): void
    {
        Http::fake([
            'api.geoapify.com/v2/places*' => Http::sequence()
                ->push(['features' => [[
                    'properties' => [
                        'place_id' => 'geoapify-opaque', 'name' => 'Pantai Baru', 'lat' => 1.1, 'lon' => 104.1, 'categories' => [],
                        'datasource' => ['raw' => ['osm_type' => 'n', 'osm_id' => 3001]],
                    ],
                ]]])
                ->push([], 500)
                ->whenEmpty(Http::response(['features' => []])),
        ]);

        // QUEUE_CONNECTION=sync in tests, so the job runs inside the request.
        $this->actingAs($this->admin)->postJson(route('admin.candidates.discover'))
            ->assertStatus(202)
            ->assertJsonPath('run.status', 'finished')
            ->assertJsonPath('run.done_steps', PlaceDiscoveryService::stepCount())
            ->assertJsonPath('run.inserted', 1)
            ->assertJsonPath('run.failed_steps', 1);

        $run = DiscoveryRun::sole();
        $this->assertCount(PlaceDiscoveryService::stepCount(), $run->log);
        $this->assertSame(1, $run->log[0]['inserted']);
        $this->assertNotNull($run->log[1]['error']);
        $this->assertNotNull($run->finished_at);
    }

    public function test_the_status_endpoint_returns_the_latest_run(): void
    {
        DiscoveryRun::create(['status' => 'finished', 'total_steps' => 36, 'done_steps' => 36]);
        DiscoveryRun::create(['status' => 'running', 'total_steps' => 36, 'done_steps' => 12, 'current_step' => 'Nongsa x culinary']);

        $this->actingAs($this->admin)->getJson(route('admin.candidates.discovery'))
            ->assertOk()
            ->assertJsonPath('run.status', 'running')
            ->assertJsonPath('run.done_steps', 12)
            ->assertJsonPath('run.current_step', 'Nongsa x culinary');
    }

    public function test_discovery_is_admin_only(): void
    {
        Queue::fake();
        $user = User::factory()->create(['role' => 'user']);

        $this->actingAs($user)->getJson(route('admin.candidates.discovery'))->assertForbidden();
        $this->actingAs($user)->postJson(route('admin.candidates.discover'))->assertForbidden();

        Queue::assertNothingPushed();
    }
}
