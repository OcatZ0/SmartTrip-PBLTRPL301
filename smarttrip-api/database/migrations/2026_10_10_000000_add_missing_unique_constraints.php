<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * PRD audit 2026-10-10: these invariants were only enforced in code
     * (firstOrCreate, usedElsewhere checks), never by the database.
     * visit_order is deliberately NOT made unique - resequenceDay() updates
     * rows one by one and would collide mid-loop.
     */
    public function up(): void
    {
        Schema::table('trip_wishlist_places', function (Blueprint $table) {
            $table->unique(['trips_id', 'places_id']);
        });

        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->unique(['trips_id', 'day_number']);
        });

        Schema::table('itinerary_items', function (Blueprint $table) {
            $table->unique(['itinerary_days_id', 'places_id']);
        });

        Schema::table('place_photos', function (Blueprint $table) {
            $table->unique(['places_id', 'sort_order']);
        });
    }

    public function down(): void
    {
        Schema::table('trip_wishlist_places', function (Blueprint $table) {
            $table->dropUnique(['trips_id', 'places_id']);
        });

        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->dropUnique(['trips_id', 'day_number']);
        });

        Schema::table('itinerary_items', function (Blueprint $table) {
            $table->dropUnique(['itinerary_days_id', 'places_id']);
        });

        Schema::table('place_photos', function (Blueprint $table) {
            $table->dropUnique(['places_id', 'sort_order']);
        });
    }
};
