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
        // docs/prd design spec Section 4: digabung dari places + place_attributes
        // (revisi 2026-09-22). Kolom kurasi admin (category_tags_reviewed..
        // description_en, kecamatan) WAJIB diproteksi lewat whitelist-update di
        // kode saat re-sync dari Google - lihat catatan di Services/ nanti,
        // bukan lewat pemisahan tabel.
        Schema::create('places', function (Blueprint $table) {
            $table->id('places_id');
            $table->string('google_place_id')->nullable()->unique();
            $table->string('name');
            $table->enum('type', ['attraction', 'culinary', 'lodging']);
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->string('address');
            $table->string('kecamatan')->nullable();
            $table->string('price_level')->nullable();
            $table->decimal('rating', 3, 2)->nullable();
            $table->unsignedInteger('review_count')->default(0);
            $table->json('opening_hours')->nullable();
            $table->string('photo_url')->nullable();
            $table->text('description')->nullable();
            $table->string('phone')->nullable();
            $table->string('website')->nullable();
            $table->enum('business_status', ['operational', 'closed_temporarily', 'closed_permanently'])
                ->default('operational');
            $table->json('types')->nullable();
            $table->enum('source', ['google', 'manual']);
            $table->boolean('category_tags_reviewed')->default(false);
            $table->unsignedInteger('estimated_visit_minutes')->nullable();
            $table->boolean('is_outdoor')->nullable();
            $table->unsignedInteger('estimated_cost_idr')->nullable();
            $table->text('description_override')->nullable();
            $table->text('description_en')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE places ADD CONSTRAINT places_estimated_cost_idr_check CHECK (estimated_cost_idr >= 0)');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('places');
    }
};
