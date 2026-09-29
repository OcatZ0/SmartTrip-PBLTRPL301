<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // docs/prd design spec Section 4: review terbuka, tidak perlu bukti
        // kunjungan. itinerary_items_id cuma keisi kalau review disubmit
        // dari flow "beri rating" pasca-kunjungan. unique(users_id, places_id)
        // - review ulang = edit yang sudah ada, bukan baris baru.
        Schema::create('place_reviews', function (Blueprint $table) {
            $table->id('place_reviews_id');
            $table->foreignId('places_id')->constrained('places', 'places_id')->cascadeOnDelete();
            $table->foreignId('users_id')->constrained('users', 'users_id')->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->text('comment')->nullable();
            $table->foreignId('itinerary_items_id')->nullable()
                ->constrained('itinerary_items', 'itinerary_items_id')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
            $table->unique(['users_id', 'places_id']);
        });

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE place_reviews ADD CONSTRAINT place_reviews_rating_check CHECK (rating BETWEEN 1 AND 5)');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('place_reviews');
    }
};
