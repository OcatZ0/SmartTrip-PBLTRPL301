<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * F007 revisi 2026-10-13: wishlist pribadi user (tombol hati di katalog,
     * tab Wishlist), lepas dari trip. trip_wishlist_places tetap jadi daftar
     * tempat per trip yang dipakai generate.
     */
    public function up(): void
    {
        Schema::create('user_wishlist_place', function (Blueprint $table) {
            $table->foreignId('users_id')->constrained('users', 'users_id')->cascadeOnDelete();
            $table->foreignId('places_id')->constrained('places', 'places_id')->cascadeOnDelete();
            $table->timestamp('added_at')->useCurrent();
            $table->unique(['users_id', 'places_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_wishlist_place');
    }
};
