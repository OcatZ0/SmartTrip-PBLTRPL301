<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

/**
 * Calls this app made today to a provider whose free plan has a daily limit
 * but no endpoint to read it (Gemini, OpenRouteService), shown on the admin
 * dashboard. Each provider resets at midnight in its own time zone, so the
 * day is counted there. Calls made outside this app (AI Studio, another
 * server with the same key) are not counted.
 */
class ApiUsage
{
    public const GEMINI = 'gemini';

    public const OPENROUTESERVICE = 'openrouteservice';

    /**
     * Where each provider's day starts: Gemini resets at midnight Pacific time.
     */
    private const TIME_ZONES = [
        self::GEMINI => 'America/Los_Angeles',
        self::OPENROUTESERVICE => 'UTC',
    ];

    public static function record(string $api, int $calls = 1): void
    {
        $key = self::key($api);
        Cache::add($key, 0, now()->addDays(2));
        Cache::increment($key, $calls);
    }

    public static function today(string $api): int
    {
        return (int) Cache::get(self::key($api), 0);
    }

    /**
     * When today's count starts again, for the dashboard.
     */
    public static function resetsAt(string $api): \Illuminate\Support\Carbon
    {
        return now(self::TIME_ZONES[$api] ?? 'UTC')->addDay()->startOfDay();
    }

    private static function key(string $api): string
    {
        return "api-usage:{$api}:".now(self::TIME_ZONES[$api] ?? 'UTC')->toDateString();
    }
}
