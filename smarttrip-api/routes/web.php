<?php

use App\Http\Controllers\Admin\AuthController as AdminAuthController;
use App\Http\Controllers\Admin\CandidateController;
use App\Http\Controllers\Admin\CategoryController as AdminCategoryController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\PlaceController as AdminPlaceController;
use App\Http\Controllers\Admin\PlacePhotoController;
use App\Http\Controllers\Api\AuthController;
use Illuminate\Support\Facades\Route;

// The site root is the admin panel's way in; the Flutter app only uses /api.
Route::redirect('/', '/admin/login');

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
    Route::get('/forgot-password', [AdminAuthController::class, 'showForgotPassword'])->name('password.request');
    Route::post('/forgot-password', [AdminAuthController::class, 'sendResetLink'])
        ->middleware('throttle:5,1')
        ->name('password.email');
    Route::post('/logout', [AdminAuthController::class, 'logout'])->name('logout');

    Route::middleware(['auth', 'admin'])->group(function () {
        Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

        Route::get('/candidates', [CandidateController::class, 'index'])->name('candidates.index');
        Route::post('/candidates/discover', [CandidateController::class, 'discover'])->name('candidates.discover');
        Route::get('/candidates/discovery', [CandidateController::class, 'discoveryStatus'])->name('candidates.discovery');
        Route::post('/candidates/{candidate}/approve', [CandidateController::class, 'approve'])->name('candidates.approve');
        Route::post('/candidates/{candidate}/reject', [CandidateController::class, 'reject'])->name('candidates.reject');
        Route::post('/candidates/bulk-approve', [CandidateController::class, 'bulkApprove'])->name('candidates.bulk-approve');
        Route::post('/candidates/bulk-reject', [CandidateController::class, 'bulkReject'])->name('candidates.bulk-reject');

        Route::get('/places', [AdminPlaceController::class, 'index'])->name('places.index');
        Route::get('/places/create', [AdminPlaceController::class, 'create'])->name('places.create');
        Route::post('/places', [AdminPlaceController::class, 'store'])->name('places.store');
        Route::get('/places/{place}/edit', [AdminPlaceController::class, 'edit'])->name('places.edit');
        Route::get('/places/{place}/activities', [AdminPlaceController::class, 'activities'])->name('places.activities');
        Route::get('/places/{place}/price-estimate', [AdminPlaceController::class, 'estimatePrice'])->name('places.price-estimate');
        Route::put('/places/{place}', [AdminPlaceController::class, 'update'])->name('places.update');
        Route::delete('/places/{place}', [AdminPlaceController::class, 'destroy'])->name('places.destroy');

        Route::post('/places/{place}/photos', [PlacePhotoController::class, 'store'])->name('places.photos.store');
        Route::get('/places/{place}/photos/google', [PlacePhotoController::class, 'search'])->name('places.photos.google');
        Route::post('/places/{place}/photos/google', [PlacePhotoController::class, 'storeFromGoogle'])->name('places.photos.google.store');
        Route::post('/places/{place}/photos/link', [PlacePhotoController::class, 'storeFromLink'])->name('places.photos.link.store');
        Route::post('/places/{place}/photos/{photo}/primary', [PlacePhotoController::class, 'primary'])->name('places.photos.primary');
        Route::delete('/places/{place}/photos/{photo}', [PlacePhotoController::class, 'destroy'])->name('places.photos.destroy');

        Route::get('/categories', [AdminCategoryController::class, 'index'])->name('categories.index');
        Route::get('/categories/create', [AdminCategoryController::class, 'create'])->name('categories.create');
        Route::post('/categories', [AdminCategoryController::class, 'store'])->name('categories.store');
        Route::get('/categories/{category}/edit', [AdminCategoryController::class, 'edit'])->name('categories.edit');
        Route::get('/categories/{category}/activities', [AdminCategoryController::class, 'activities'])->name('categories.activities');
        Route::put('/categories/{category}', [AdminCategoryController::class, 'update'])->name('categories.update');
        Route::delete('/categories/{category}', [AdminCategoryController::class, 'destroy'])->name('categories.destroy');
    });
});
