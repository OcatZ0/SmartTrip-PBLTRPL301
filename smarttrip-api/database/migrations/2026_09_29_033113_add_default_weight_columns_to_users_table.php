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
        // docs/prd design spec Section 4: default bobot 4 kriteria TOPSIS,
        // pre-fill saja untuk trip baru - null sampai user pertama kali isi.
        Schema::table('users', function (Blueprint $table) {
            $table->decimal('default_weight_kategori', 4, 3)->nullable()->after('role');
            $table->decimal('default_weight_jarak', 4, 3)->nullable()->after('default_weight_kategori');
            $table->decimal('default_weight_anggaran', 4, 3)->nullable()->after('default_weight_jarak');
            $table->decimal('default_weight_rating', 4, 3)->nullable()->after('default_weight_anggaran');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn([
                'default_weight_kategori',
                'default_weight_jarak',
                'default_weight_anggaran',
                'default_weight_rating',
            ]);
        });
    }
};
