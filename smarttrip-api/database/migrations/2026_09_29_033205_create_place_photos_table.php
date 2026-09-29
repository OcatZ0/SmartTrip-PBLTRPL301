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
        // docs/prd design spec Section 4: diisi dari Google photos[] saat
        // sync, dipakai buat carousel di detail screen. Tidak ada timestamps
        // /deleted_at di spec - murni child row, ikut terhapus bareng places.
        Schema::create('place_photos', function (Blueprint $table) {
            $table->id('place_photos_id');
            $table->foreignId('places_id')->constrained('places', 'places_id')->cascadeOnDelete();
            $table->string('photo_url');
            $table->unsignedInteger('sort_order')->default(0);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('place_photos');
    }
};
