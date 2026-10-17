<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    ],

    'geoapify' => [
        'api_key' => env('GEOAPIFY_API_KEY'),
        'daily_credits' => env('GEOAPIFY_DAILY_CREDITS', 3000),
    ],

    'serpapi' => [
        'api_key' => env('SERPAPI_API_KEY'),
        // Automatic Google lookups (candidate approval, places:enrich) stop
        // while this many searches or fewer are left this month, keeping them
        // for the admin's buttons.
        'reserve' => env('SERPAPI_RESERVE', 50),
    ],

    'openrouteservice' => [
        'api_key' => env('ORS_API_KEY'),
        // Standard (free) plan: 2,000 directions a day, shown on the dashboard.
        'daily_limit' => env('ORS_DAILY_LIMIT', 2000),
    ],

    'gemini' => [
        'api_key' => env('GEMINI_API_KEY'),
        // An alias, so a retired version (gemini-2.0-flash returned 404 in
        // 2026-10) does not break enrichment again.
        'model' => env('GEMINI_MODEL', 'gemini-flash-lite-latest'),
        // Free tier requests per day for that model, shown on the dashboard
        // (AI Studio, Rate limit page: Gemini 3.5 Flash Lite, 500 RPD).
        'daily_limit' => env('GEMINI_DAILY_LIMIT', 500),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

];
