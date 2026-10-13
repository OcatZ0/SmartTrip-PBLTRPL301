<?php

namespace App\Providers;

use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Postgres rejects a non-numeric id with a query error (500); a
        // numeric-only parameter turns /places/abc into a plain 404.
        Route::pattern('place', '[0-9]+');
    }
}
