<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Timestamps nothing reads (the ERD keeps only the used ones): categories
     * and users never show when they were made or changed, and an edit to a
     * place, trip, review or log entry is already recorded in activity_log.
     * created_at stays where it orders or dates something; updated_at stays
     * on discovery_runs (stale-run check) and place_candidates.
     */
    private const DROPS = [
        'categories' => ['created_at', 'updated_at'],
        'users' => ['created_at', 'updated_at'],
        'places' => ['updated_at'],
        'trips' => ['updated_at'],
        'place_reviews' => ['updated_at'],
        'activity_log' => ['updated_at'],
    ];

    public function up(): void
    {
        foreach (self::DROPS as $table => $columns) {
            Schema::table($table, function (Blueprint $blueprint) use ($columns) {
                $blueprint->dropColumn($columns);
            });
        }
    }

    public function down(): void
    {
        foreach (self::DROPS as $table => $columns) {
            Schema::table($table, function (Blueprint $blueprint) use ($columns) {
                foreach ($columns as $column) {
                    $blueprint->timestamp($column)->nullable();
                }
            });
        }
    }
};
