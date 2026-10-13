<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A custom-pin wishlist row (trip_wishlist_places with places_id null)
     * has no places row, but generate() still turns it into an itinerary
     * stop - with places_id NOT NULL that insert failed. The stop now
     * carries a snapshot of the pin, the same shape as trip_wishlist_places,
     * so the itinerary stays intact even if the wishlist row is removed.
     */
    public function up(): void
    {
        Schema::table('itinerary_items', function (Blueprint $table) {
            $table->foreignId('places_id')->nullable()->change();
            $table->string('custom_name')->nullable();
            $table->decimal('custom_lat', 10, 7)->nullable();
            $table->decimal('custom_lng', 10, 7)->nullable();
            $table->unsignedInteger('custom_visit_minutes')->nullable();
        });

        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement(<<<'SQL'
                ALTER TABLE itinerary_items ADD CONSTRAINT itinerary_items_place_or_pin_check CHECK (
                    (places_id IS NOT NULL)
                    OR (custom_name IS NOT NULL AND custom_lat IS NOT NULL AND custom_lng IS NOT NULL AND custom_visit_minutes IS NOT NULL)
                )
            SQL);
        }
    }

    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE itinerary_items DROP CONSTRAINT IF EXISTS itinerary_items_place_or_pin_check');
        }

        DB::table('itinerary_items')->whereNull('places_id')->delete();

        Schema::table('itinerary_items', function (Blueprint $table) {
            $table->dropColumn(['custom_name', 'custom_lat', 'custom_lng', 'custom_visit_minutes']);
            $table->foreignId('places_id')->nullable(false)->change();
        });
    }
};
