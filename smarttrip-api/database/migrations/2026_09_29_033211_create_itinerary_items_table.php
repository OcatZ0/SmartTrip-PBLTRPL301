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
        // docs/prd design spec Section 4: topsis_score nullable - snapshot
        // saat generate/swap dari ranking, NULL kalau hasil swap cari manual
        // (tidak pernah difabrikasi). visited_at diisi otomatis lewat
        // geofence trigger dari mobile, atau manual toggle (US7).
        Schema::create('itinerary_items', function (Blueprint $table) {
            $table->id('itinerary_items_id');
            $table->foreignId('itinerary_days_id')->constrained('itinerary_days', 'itinerary_days_id')->cascadeOnDelete();
            $table->foreignId('places_id')->constrained('places', 'places_id')->restrictOnDelete();
            $table->unsignedInteger('visit_order');
            $table->decimal('topsis_score', 8, 4)->nullable();
            $table->enum('source', ['wishlist', 'recommended']);
            $table->text('polyline_to_here')->nullable();
            $table->timestamp('visited_at')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('itinerary_items');
    }
};
