<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * The Indonesian text sits next to description_en and
     * description_override; the API already sends it as description_id.
     */
    public function up(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->renameColumn('description', 'description_id');
        });
    }

    public function down(): void
    {
        Schema::table('places', function (Blueprint $table) {
            $table->renameColumn('description_id', 'description');
        });
    }
};
