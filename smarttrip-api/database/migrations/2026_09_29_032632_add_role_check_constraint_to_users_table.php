<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // docs/prd design spec Section 4: role is `user`/`admin`, nothing
        // else. Same pgsql-only caveat as the password CHECK (see
        // 2026_09_29_031635_...) - SQLite tests run without it.
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement(
                "ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('user', 'admin'))"
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT users_role_check');
        }
    }
};
