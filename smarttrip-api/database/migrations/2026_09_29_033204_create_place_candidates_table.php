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
        // docs/prd design spec Section 4: staging area hasil fase Discovery
        // (Section 3) - cuma field dasar/murah. status=rejected sudah
        // berfungsi sebagai "soft delete"-nya sendiri, tidak butuh deleted_at.
        Schema::create('place_candidates', function (Blueprint $table) {
            $table->id('place_candidates_id');
            $table->string('google_place_id')->unique();
            $table->string('name');
            $table->string('type');
            $table->decimal('lat', 10, 7);
            $table->decimal('lng', 10, 7);
            $table->string('search_area');
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('place_candidates');
    }
};
