<?php

use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\CandidateController;
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

        Route::get('/candidates', [CandidateController::class, 'index'])->name('candidates.index');
        Route::post('/candidates/discover', [CandidateController::class, 'discover'])->name('candidates.discover');
        Route::post('/candidates/{candidate}/approve', [CandidateController::class, 'approve'])->name('candidates.approve');
        Route::post('/candidates/{candidate}/reject', [CandidateController::class, 'reject'])->name('candidates.reject');
        Route::post('/candidates/bulk-approve', [CandidateController::class, 'bulkApprove'])->name('candidates.bulk-approve');
        Route::post('/candidates/bulk-reject', [CandidateController::class, 'bulkReject'])->name('candidates.bulk-reject');
    });
});
