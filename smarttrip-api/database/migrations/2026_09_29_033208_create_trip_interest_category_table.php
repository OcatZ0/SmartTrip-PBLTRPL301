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
        // docs/prd design spec Section 4: minat yang dipilih user buat
        // satu trip spesifik - ISI buat Jaccard similarity di Section 7.
        Schema::create('trip_interest_category', function (Blueprint $table) {
            $table->foreignId('trips_id')->constrained('trips', 'trips_id')->cascadeOnDelete();
            $table->foreignId('categories_id')->constrained('categories', 'categories_id')->restrictOnDelete();
            $table->unique(['trips_id', 'categories_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trip_interest_category');
    }
};
