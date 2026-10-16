<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Search keywords belong to each place, not to a whole category: "snorkeling"
 * fits Pulau Abang but not every beach. Category keywords are not copied to
 * the places in that category, since they would be wrong for many of them
 * (on 2026-10-16 only "Pantai" had any).
 */
return new class extends Migration
{
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->text('search_keywords')->nullable();
        });

        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('search_keywords');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->text('search_keywords')->nullable();
        });

        Schema::table('places', function (Blueprint $table) {
            $table->dropColumn('search_keywords');
        });
    }
};
