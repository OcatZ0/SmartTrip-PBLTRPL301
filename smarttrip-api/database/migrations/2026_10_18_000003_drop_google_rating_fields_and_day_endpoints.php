<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * places.price_level, rating and review_count came from Google Places;
     * Geoapify has none of them, so they stayed empty on every place and the
     * rating the app shows is the in-app review average. itinerary_days
     * start/end places only copied trips.hotel_places_id and were never read.
     */
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn(['price_level', 'rating', 'review_count']);
        });

        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->dropForeign(['start_places_id']);
            $table->dropForeign(['end_places_id']);
            $table->dropColumn(['start_places_id', 'end_places_id']);
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->string('price_level')->nullable();
            $table->decimal('rating', 3, 2)->nullable();
            $table->unsignedInteger('review_count')->default(0);
        });

        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->foreignId('start_places_id')->nullable()->constrained('places', 'places_id')->restrictOnDelete();
            $table->foreignId('end_places_id')->nullable()->constrained('places', 'places_id')->restrictOnDelete();
        });
    }
};
