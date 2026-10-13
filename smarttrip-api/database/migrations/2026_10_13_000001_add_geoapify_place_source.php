<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Places promoted from Geoapify candidates (the provider that replaced
     * Google Places on 2026-10-13) are recorded as such, so the admin panel
     * can tell them apart from Google-sourced and hand-entered places.
     */
    public function up(): void
    {
        $this->allowSources(['google', 'geoapify', 'manual']);
    }

    public function down(): void
    {
        DB::table('places')->where('source', 'geoapify')->update(['source' => 'google']);

        $this->allowSources(['google', 'manual']);
    }

    /**
     * Laravel's enum ->change() emits invalid SQL on PostgreSQL, where the
     * enum is a varchar plus the places_source_check constraint, so that
     * constraint is swapped directly there.
     */
    private function allowSources(array $sources): void
    {
        if (Schema::getConnection()->getDriverName() !== 'pgsql') {
            Schema::table('places', function (Blueprint $table) use ($sources) {
                $table->enum('source', $sources)->change();
            });

            return;
        }

        $list = implode(', ', array_map(fn (string $source) => "'{$source}'", $sources));
        DB::statement('ALTER TABLE places DROP CONSTRAINT IF EXISTS places_source_check');
        DB::statement("ALTER TABLE places ADD CONSTRAINT places_source_check CHECK (source IN ({$list}))");
    }
};
