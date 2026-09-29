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
        // docs/prd design spec Section 4: start/end_places_id biasanya =
        // hotel di kedua ujung hari itu. Murni child row punya trips -
        // tidak ada deleted_at sendiri (ikut terhapus bareng trip).
        Schema::create('itinerary_days', function (Blueprint $table) {
            $table->id('itinerary_days_id');
            $table->foreignId('trips_id')->constrained('trips', 'trips_id')->cascadeOnDelete();
            $table->unsignedInteger('day_number');
            $table->foreignId('start_places_id')->constrained('places', 'places_id')->restrictOnDelete();
            $table->foreignId('end_places_id')->constrained('places', 'places_id')->restrictOnDelete();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('itinerary_days');
    }
};
