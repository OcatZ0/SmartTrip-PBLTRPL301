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
        // docs/prd design spec Section 9: pivot undangan read-only murni -
        // tidak ada kolom role, cuma satu level akses (viewer). "Cabut akses
        // viewer" = hard delete baris ini, makanya tidak ada deleted_at.
        Schema::create('trip_viewers', function (Blueprint $table) {
            $table->id('trip_viewers_id');
            $table->foreignId('trips_id')->constrained('trips', 'trips_id')->cascadeOnDelete();
            $table->foreignId('users_id')->constrained('users', 'users_id')->cascadeOnDelete();
            $table->timestamp('added_at');
            $table->unique(['trips_id', 'users_id']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('trip_viewers');
    }
};
