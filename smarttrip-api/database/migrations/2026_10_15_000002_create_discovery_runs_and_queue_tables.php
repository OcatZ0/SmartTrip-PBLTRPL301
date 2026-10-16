<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Discovery now runs on the database queue, so the admin can leave the
     * page; jobs and failed_jobs come back (dropped on 2026-10-11 when nothing
     * was queued). discovery_runs holds each run's progress for the modal and
     * keeps the history.
     */
    public function up(): void
    {
        Schema::create('jobs', function (Blueprint $table) {
            $table->id();
            $table->string('queue')->index();
            $table->longText('payload');
            $table->unsignedTinyInteger('attempts');
            $table->unsignedInteger('reserved_at')->nullable();
            $table->unsignedInteger('available_at');
            $table->unsignedInteger('created_at');
        });

        Schema::create('failed_jobs', function (Blueprint $table) {
            $table->id();
            $table->string('uuid')->unique();
            $table->text('connection');
            $table->text('queue');
            $table->longText('payload');
            $table->longText('exception');
            $table->timestamp('failed_at')->useCurrent();
        });

        Schema::create('discovery_runs', function (Blueprint $table) {
            $table->id('discovery_runs_id');
            $table->foreignId('users_id')->nullable()->constrained('users', 'users_id')->nullOnDelete();
            $table->enum('status', ['queued', 'running', 'finished', 'failed'])->default('queued');
            $table->unsignedInteger('total_steps');
            $table->unsignedInteger('done_steps')->default(0);
            $table->string('current_step')->nullable();
            $table->unsignedInteger('inserted')->default(0);
            $table->unsignedInteger('skipped')->default(0);
            $table->unsignedInteger('failed_steps')->default(0);
            $table->json('log')->nullable();
            $table->text('error')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('finished_at')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('discovery_runs');
        Schema::dropIfExists('failed_jobs');
        Schema::dropIfExists('jobs');
    }
};
