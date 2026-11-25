<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

/**
 * Photos uploaded to this server were saved with the domain of the day
 * (smarttrip.filltech.network, then smarttrips.my.id), so moving the site
 * meant rewriting them by hand. They become public-disk paths; Place and
 * PlacePhoto add the current APP_URL when read. Links to other sites stay.
 */
return new class extends Migration
{
    private const TABLES = ['place_photos' => 'place_photos_id', 'places' => 'places_id'];

    public function up(): void
    {
        foreach (self::TABLES as $table => $key) {
            DB::table($table)->select([$key, 'photo_url'])->where('photo_url', 'like', '%/storage/%')->get()
                ->each(function ($row) use ($table, $key) {
                    if (preg_match('#^https?://[^/]+/storage/((?:place-photos|places)/.+)$#i', $row->photo_url, $match)) {
                        DB::table($table)->where($key, $row->{$key})->update(['photo_url' => $match[1]]);
                    }
                });
        }
    }

    public function down(): void
    {
        foreach (self::TABLES as $table => $key) {
            DB::table($table)->select([$key, 'photo_url'])
                ->where(fn ($query) => $query->where('photo_url', 'like', 'place-photos/%')->orWhere('photo_url', 'like', 'places/%'))
                ->get()
                ->each(fn ($row) => DB::table($table)->where($key, $row->{$key})->update(['photo_url' => Storage::disk('public')->url($row->photo_url)]));
        }
    }
};
