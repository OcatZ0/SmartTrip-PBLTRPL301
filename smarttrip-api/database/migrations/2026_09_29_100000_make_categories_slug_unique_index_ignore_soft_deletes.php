<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * F022: sama persis dengan bug unique(users_id, places_id) di
     * place_reviews yang diperbaiki di F014 - categories.slug punya
     * unique() plain dari migration awal, ikut menghitung baris yang
     * sudah soft-deleted. Efeknya slug kategori yang sudah dihapus admin
     * tidak bisa dipakai ulang buat kategori baru (INSERT bentrok sama
     * baris lama yang deleted_at-nya terisi). Ganti jadi partial unique
     * index (WHERE deleted_at IS NULL), didukung Postgres maupun SQLite.
     */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropUnique(['slug']);
        });

        DB::statement('CREATE UNIQUE INDEX categories_slug_unique ON categories (slug) WHERE deleted_at IS NULL');
    }

    public function down(): void
    {
        DB::statement('DROP INDEX categories_slug_unique');

        Schema::table('categories', function (Blueprint $table) {
            $table->unique('slug');
        });
    }
};
