<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * F014: unique(users_id, places_id) dari migration awal itu plain -
     * mencakup baris yang sudah soft-deleted juga, jadi setelah user hapus
     * review-nya sendiri, dia tidak bisa review ulang tempat yang sama
     * (INSERT baru bentrok sama baris lama yang masih ada, cuma
     * deleted_at-nya terisi). Ganti jadi partial unique index (cuma
     * berlaku buat baris yang deleted_at-nya NULL) - didukung Postgres
     * maupun SQLite (dipakai test suite), jadi tidak perlu diguard per
     * driver kayak CHECK constraint di migration lain.
     */
    public function up(): void
    {
        Schema::table('place_reviews', function (Blueprint $table) {
            $table->dropUnique(['users_id', 'places_id']);
        });

        DB::statement(
            'CREATE UNIQUE INDEX place_reviews_users_id_places_id_unique ON place_reviews (users_id, places_id) WHERE deleted_at IS NULL'
        );
    }

    public function down(): void
    {
        DB::statement('DROP INDEX place_reviews_users_id_places_id_unique');

        Schema::table('place_reviews', function (Blueprint $table) {
            $table->unique(['users_id', 'places_id']);
        });
    }
};
