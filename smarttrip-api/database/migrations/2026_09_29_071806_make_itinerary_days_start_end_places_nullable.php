<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // docs/prd design spec Section 4 lists start_places_id/end_places_id
        // as plain (non-nullable) FKs, but trips.hotel_* explicitly supports
        // a custom-pin hotel (no places row at all) - a gap found while
        // building generate() (F008). Nullable here, with the day's
        // start/end implicitly being trips.hotel_lat/hotel_lng when null.
        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->foreignId('start_places_id')->nullable()->change();
            $table->foreignId('end_places_id')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->foreignId('start_places_id')->nullable(false)->change();
            $table->foreignId('end_places_id')->nullable(false)->change();
        });
    }
};
