<?php

use App\Services\Places\OpeningHours;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * places.opening_hours kept weekday_descriptions next to periods, but the
     * lines were made from the periods, so they now come from
     * OpeningHours::describe() in the API and only the hours per day stay.
     * Older Geoapify places held {"osm": "..."}, read once here.
     */
    public function up(): void
    {
        $this->convert(function (array $hours): ?array {
            if (is_array($hours['periods'] ?? null)) {
                return OpeningHours::periods($hours['periods']) ?: null;
            }
            if (is_array($hours['weekday_descriptions'] ?? null)) {
                return OpeningHours::fromLines($hours['weekday_descriptions']);
            }
            if (is_string($hours['osm'] ?? null)) {
                return OpeningHours::fromOsm($hours['osm']);
            }

            return OpeningHours::periods($hours) ?: null;
        });
    }

    public function down(): void
    {
        $this->convert(function (array $hours): ?array {
            $periods = OpeningHours::periods($hours);
            if ($periods === []) {
                return null;
            }

            $old = ['weekday_descriptions' => OpeningHours::describe($periods)];

            return count($periods) === count(OpeningHours::DAYS) ? $old + ['periods' => $periods] : $old;
        });
    }

    private function convert(callable $change): void
    {
        DB::table('places')->whereNotNull('opening_hours')->orderBy('places_id')->get(['places_id', 'opening_hours'])
            ->each(function ($place) use ($change) {
                $hours = json_decode($place->opening_hours, true);
                $converted = is_array($hours) ? $change($hours) : null;

                DB::table('places')->where('places_id', $place->places_id)
                    ->update(['opening_hours' => $converted === null ? null : json_encode($converted, JSON_UNESCAPED_UNICODE)]);
            });
    }
};
