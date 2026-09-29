<?php

use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Public registration/account-link verification link opened from the email
// client (see AuthController::register / verifyRegistration).
Route::get('/auth/verify-registration', [AuthController::class, 'verifyRegistration'])
    ->middleware('signed')
    ->name('auth.verify-registration');

// F004 - lupa password: form web sederhana yang dibuka dari link email
// (Password::reset() sendiri yang verifikasi token, bukan signed URL).
Route::get('/auth/reset-password', [AuthController::class, 'showResetPasswordForm'])
    ->name('auth.reset-password.form');
Route::post('/auth/reset-password', [AuthController::class, 'submitResetPasswordForm'])
    ->name('auth.reset-password.submit');

// Admin web panel (Blade + Bootstrap, session auth) - docs/prd Section 8.
// Entirely separate from routes/api.php, which the Flutter app consumes.
Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminAuthController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminAuthController::class, 'login'])->name('login.attempt');
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');
    });
});
