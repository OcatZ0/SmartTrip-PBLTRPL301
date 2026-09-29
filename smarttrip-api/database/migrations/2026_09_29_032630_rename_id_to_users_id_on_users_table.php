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
        // docs/prd Section 10 PK/FK naming convention: every primary key is
        // `{table}_id`, not the generic `id` - sessions.user_id and
        // personal_access_tokens.tokenable_id are left as-is, they're
        // Laravel/Sanctum-owned tables (same exception as activity_log).
        Schema::table('users', function (Blueprint $table) {
            $table->renameColumn('id', 'users_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->renameColumn('users_id', 'id');
        });
    }
};
