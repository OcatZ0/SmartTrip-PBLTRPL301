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
        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable()->change();
        });

        // CHECK constraints can't be added to an existing SQLite table via
        // ALTER TABLE (tests run on SQLite - RefreshDatabase), so this is
        // pgsql-only; app-level validation still guards this in code too.
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement(
                'ALTER TABLE users ADD CONSTRAINT users_password_or_google_id_check '.
                'CHECK (password IS NOT NULL OR google_id IS NOT NULL)'
            );
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::getConnection()->getDriverName() === 'pgsql') {
            DB::statement('ALTER TABLE users DROP CONSTRAINT users_password_or_google_id_check');
        }

        Schema::table('users', function (Blueprint $table) {
            $table->string('password')->nullable(false)->change();
        });
    }
};
