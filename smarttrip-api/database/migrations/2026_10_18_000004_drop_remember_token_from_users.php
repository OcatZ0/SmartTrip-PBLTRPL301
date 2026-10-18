<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * remember_token backs the "remember me" cookie of web login. The admin
     * login has no remember option and the app signs in with Sanctum tokens,
     * so only the factory ever wrote it.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('remember_token');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->rememberToken();
        });
    }
};
