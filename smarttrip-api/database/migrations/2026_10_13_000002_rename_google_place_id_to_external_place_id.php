<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The place id now comes from Geoapify (it replaced Google Places on
     * 2026-10-13), so the column gets a provider-neutral name.
     */
    public function up(): void
    {
        $this->rename('google_place_id', 'external_place_id');
    }

    public function down(): void
    {
        $this->rename('external_place_id', 'google_place_id');
    }

    private function rename(string $from, string $to): void
    {
        foreach (['places', 'place_candidates'] as $table) {
            Schema::table($table, fn (Blueprint $blueprint) => $blueprint->renameColumn($from, $to));

            // Separate call: SQLite rebuilds the index from the schema it
            // read when the Blueprint started, which still has the old column.
            Schema::table($table, fn (Blueprint $blueprint) => $blueprint->renameIndex("{$table}_{$from}_unique", "{$table}_{$to}_unique"));
        }
    }
};
