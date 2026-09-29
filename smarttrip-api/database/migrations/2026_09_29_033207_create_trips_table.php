<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // docs/prd design spec Section 4: users_id wajib (tidak ada trip
        // guest). weight_* = snapshot bobot 4 kriteria buat trip ini (dulu
        // tabel EAV trip_criteria_weights). viewer_invite_token (US16) dan
        // share_token (US17) adalah 2 mekanisme berbeda, jangan disatukan.
        Schema::create('trips', function (Blueprint $table) {
            $table->id('trips_id');
            $table->foreignId('users_id')->constrained('users', 'users_id')->cascadeOnDelete();
            $table->string('title');
            $table->unsignedInteger('num_days');
            $table->unsignedInteger('budget_total');
            $table->boolean('has_own_hotel')->default(false);
            $table->foreignId('hotel_places_id')->nullable()->constrained('places', 'places_id')->nullOnDelete();
            $table->string('hotel_custom_name')->nullable();
            $table->decimal('hotel_lat', 10, 7)->nullable();
            $table->decimal('hotel_lng', 10, 7)->nullable();
            $table->date('start_date');
            $table->time('daily_start_time')->default('09:00:00');
            $table->time('daily_end_time')->default('19:00:00');
            $table->decimal('weight_kategori', 4, 3)->nullable();
            $table->decimal('weight_jarak', 4, 3)->nullable();
            $table->decimal('weight_anggaran', 4, 3)->nullable();
            $table->decimal('weight_rating', 4, 3)->nullable();
            $table->string('viewer_invite_token')->nullable()->unique();
            $table->string('share_token')->nullable()->unique();
            $table->timestamps();
            $table->softDeletes();
        });

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE trips ADD CONSTRAINT trips_num_days_check CHECK (num_days >= 1)');
            DB::statement('ALTER TABLE trips ADD CONSTRAINT trips_budget_total_check CHECK (budget_total > 0)');
            DB::statement('ALTER TABLE trips ADD CONSTRAINT trips_daily_time_check CHECK (daily_end_time > daily_start_time)');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trips');
    }
};
