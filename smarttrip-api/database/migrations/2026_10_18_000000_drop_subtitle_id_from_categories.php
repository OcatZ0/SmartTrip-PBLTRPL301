<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * subtitle_id only showed as a line under the name in the admin category
     * list; the app never received it and no category had one.
     */
    public function up(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->dropColumn('subtitle_id');
        });
    }

    public function down(): void
    {
        Schema::table('categories', function (Blueprint $table) {
            $table->string('subtitle_id')->nullable();
        });
    }
};
