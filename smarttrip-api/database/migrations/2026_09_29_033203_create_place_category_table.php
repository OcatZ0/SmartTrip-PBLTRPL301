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
        // docs/prd design spec Section 4: pivot standar many-to-many,
        // diisi AI + admin-editable. ON DELETE RESTRICT: kategori yang
        // masih dipakai tidak boleh terhapus.
        Schema::create('place_category', function (Blueprint $table) {
            $table->foreignId('places_id')->constrained('places', 'places_id')->restrictOnDelete();
            $table->foreignId('categories_id')->constrained('categories', 'categories_id')->restrictOnDelete();
            $table->unique(['places_id', 'categories_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('place_category');
    }
};
