<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

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

        $this->configureAuthRateLimits();
    }

    /**
     * Per email+IP so one account can't be brute-forced, plus a looser per-IP
     * cap so a campus NAT shared by a whole class still works.
     */
    private function configureAuthRateLimits(): void
    {
        $tooMany = function (Request $request, array $headers) {
            $minutes = (int) ceil(((int) ($headers['Retry-After'] ?? 60)) / 60);
            $message = "Terlalu banyak percobaan. Coba lagi dalam {$minutes} menit.";

            if ($request->expectsJson() || $request->is('api/*')) {
                return response()->json(['message' => $message, 'errors' => ['email' => [$message]]], 429, $headers);
            }

            return back()->withErrors(['email' => $message])->withInput($request->except('password'));
        };

        $emailKey = fn (Request $request) => Str::lower((string) $request->input('email'));

        RateLimiter::for('login', fn (Request $request) => [
            Limit::perMinute(5)->by('login:'.$emailKey($request).'|'.$request->ip())->response($tooMany),
            Limit::perMinute(20)->by('login-ip:'.$request->ip())->response($tooMany),
        ]);

        // Every request here sends an email through EmailJS, whose monthly
        // quota is shared by every user.
        RateLimiter::for('auth-email', fn (Request $request) => [
            Limit::perHour(3)->by('auth-email:'.$emailKey($request))->response($tooMany),
            Limit::perHour(20)->by('auth-email-ip:'.$request->ip())->response($tooMany),
        ]);
    }
}
