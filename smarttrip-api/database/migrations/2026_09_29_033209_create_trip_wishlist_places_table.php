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
        // docs/prd design spec Section 4: custom_* cuma keisi kalau places_id
        // null (pin custom di luar katalog). custom_visit_minutes wajib di
        // jalur itu karena tidak ada baris places buat sumber
        // estimated_visit_minutes (revisi 2026-09-22, gap ditemukan).
        Schema::create('trip_wishlist_places', function (Blueprint $table) {
            $table->id('trip_wishlist_places_id');
            $table->foreignId('trips_id')->constrained('trips', 'trips_id')->cascadeOnDelete();
            $table->foreignId('places_id')->nullable()->constrained('places', 'places_id')->cascadeOnDelete();
            $table->string('custom_name')->nullable();
            $table->decimal('custom_lat', 10, 7)->nullable();
            $table->decimal('custom_lng', 10, 7)->nullable();
            $table->unsignedInteger('custom_visit_minutes')->nullable();
        });

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement(<<<'SQL'
                ALTER TABLE trip_wishlist_places ADD CONSTRAINT trip_wishlist_places_source_check CHECK (
                    (places_id IS NOT NULL)
                    OR (custom_name IS NOT NULL AND custom_lat IS NOT NULL AND custom_lng IS NOT NULL AND custom_visit_minutes IS NOT NULL)
                )
            SQL);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trip_wishlist_places');
    }
};
