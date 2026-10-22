<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * A trip can move hotels mid-way, so where a day starts and ends belongs
     * to the day, not the trip: trips.hotel_* only ever held the first hotel.
     * Every trip gets its day rows (1..num_days) now, filled with the hotel it
     * had, and the day rows outlive regenerating the itinerary.
     */
    public function up(): void
    {
        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->foreignId('start_places_id')->nullable()->constrained('places', 'places_id')->nullOnDelete();
            $table->string('start_custom_name')->nullable();
            $table->decimal('start_lat', 10, 7)->nullable();
            $table->decimal('start_lng', 10, 7)->nullable();
            // An empty end means the day ends where it starts.
            $table->foreignId('end_places_id')->nullable()->constrained('places', 'places_id')->nullOnDelete();
            $table->string('end_custom_name')->nullable();
            $table->decimal('end_lat', 10, 7)->nullable();
            $table->decimal('end_lng', 10, 7)->nullable();
            $table->text('polyline_to_end')->nullable();
        });

        $trips = DB::table('trips')->select('trips_id', 'num_days', 'hotel_places_id', 'hotel_custom_name', 'hotel_lat', 'hotel_lng')->get();

        foreach ($trips as $trip) {
            $start = $trip->hotel_places_id !== null
                ? ['start_places_id' => $trip->hotel_places_id]
                : ($trip->hotel_lat !== null && $trip->hotel_lng !== null
                    ? ['start_custom_name' => $trip->hotel_custom_name, 'start_lat' => $trip->hotel_lat, 'start_lng' => $trip->hotel_lng]
                    : []);

            $existing = DB::table('itinerary_days')->where('trips_id', $trip->trips_id)->pluck('day_number')->all();

            for ($dayNumber = 1; $dayNumber <= max(1, (int) $trip->num_days); $dayNumber++) {
                if (! in_array($dayNumber, $existing, false)) {
                    DB::table('itinerary_days')->insert(['trips_id' => $trip->trips_id, 'day_number' => $dayNumber]);
                }
            }

            if ($start !== []) {
                DB::table('itinerary_days')->where('trips_id', $trip->trips_id)->update($start);
            }
        }

        Schema::table('trips', function (Blueprint $table) {
            $table->dropForeign(['hotel_places_id']);
            $table->dropColumn(['hotel_places_id', 'hotel_custom_name', 'hotel_lat', 'hotel_lng']);
        });

        if (DB::getDriverName() === 'pgsql') {
            // A point is a catalog place or a custom pin, never both.
            DB::statement('ALTER TABLE itinerary_days ADD CONSTRAINT itinerary_days_start_one_kind CHECK (start_places_id IS NULL OR (start_lat IS NULL AND start_lng IS NULL))');
            DB::statement('ALTER TABLE itinerary_days ADD CONSTRAINT itinerary_days_end_one_kind CHECK (end_places_id IS NULL OR (end_lat IS NULL AND end_lng IS NULL))');
        }
    }

    public function down(): void
    {
        Schema::table('trips', function (Blueprint $table) {
            $table->foreignId('hotel_places_id')->nullable()->constrained('places', 'places_id')->nullOnDelete();
            $table->string('hotel_custom_name')->nullable();
            $table->decimal('hotel_lat', 10, 7)->nullable();
            $table->decimal('hotel_lng', 10, 7)->nullable();
        });

        // Day 1's start becomes the trip hotel again.
        foreach (DB::table('itinerary_days')->where('day_number', 1)->get() as $day) {
            DB::table('trips')->where('trips_id', $day->trips_id)->update([
                'hotel_places_id' => $day->start_places_id,
                'hotel_custom_name' => $day->start_custom_name,
                'hotel_lat' => $day->start_lat,
                'hotel_lng' => $day->start_lng,
            ]);
        }

        if (DB::getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE itinerary_days DROP CONSTRAINT IF EXISTS itinerary_days_start_one_kind');
            DB::statement('ALTER TABLE itinerary_days DROP CONSTRAINT IF EXISTS itinerary_days_end_one_kind');
        }

        Schema::table('itinerary_days', function (Blueprint $table) {
            $table->dropForeign(['start_places_id']);
            $table->dropForeign(['end_places_id']);
            $table->dropColumn([
                'start_places_id', 'start_custom_name', 'start_lat', 'start_lng',
                'end_places_id', 'end_custom_name', 'end_lat', 'end_lng', 'polyline_to_end',
            ]);
        });
    }
};
