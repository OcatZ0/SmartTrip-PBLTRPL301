<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    // Sama seperti place_reviews dan categories.slug: unique biasa ikut menghitung akun soft-deleted, jadi email/google_id akun yang dinonaktifkan tidak bisa dipakai daftar ulang.
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['email']);
            $table->dropUnique(['google_id']);
        });

        DB::statement('CREATE UNIQUE INDEX users_email_unique ON users (email) WHERE deleted_at IS NULL');
        DB::statement('CREATE UNIQUE INDEX users_google_id_unique ON users (google_id) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX users_email_unique');
        DB::statement('DROP INDEX users_google_id_unique');

        Schema::table('users', function (Blueprint $table) {
            $table->unique('email');
            $table->unique('google_id');
        });
    }
};
