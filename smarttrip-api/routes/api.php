<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ItineraryItemController;
use App\Http\Controllers\Api\PlaceController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\TripController;
use App\Http\Controllers\Api\WishlistController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/places', [PlaceController::class, 'index']);
Route::get('/places/{place}', [PlaceController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/profile/preferences', [ProfileController::class, 'show']);
    Route::put('/profile/preferences', [ProfileController::class, 'update']);

    Route::get('/trips', [TripController::class, 'index']);
    Route::post('/trips', [TripController::class, 'store']);
    Route::get('/trips/{trip}', [TripController::class, 'show']);
    Route::delete('/trips/{trip}', [TripController::class, 'destroy']);
    Route::post('/trips/{trip}/weights', [TripController::class, 'weights']);
    Route::post('/trips/{trip}/hotel', [TripController::class, 'hotel']);
    Route::get('/trips/{trip}/hotel-options', [TripController::class, 'hotelOptions']);
    Route::post('/trips/{trip}/generate', [TripController::class, 'generate']);

    Route::get('/trips/{trip}/wishlist', [WishlistController::class, 'index']);
    Route::post('/trips/{trip}/wishlist', [WishlistController::class, 'store']);
    Route::delete('/trips/{trip}/wishlist/{wishlist}', [WishlistController::class, 'destroy']);

    Route::get('/itinerary-items/{itineraryItem}/swap-candidates', [ItineraryItemController::class, 'swapCandidates']);
    Route::patch('/itinerary-items/{itineraryItem}', [ItineraryItemController::class, 'update']);
});

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/google', [AuthController::class, 'loginWithGoogle']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
    Route::post('/logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::put('/password', [AuthController::class, 'changePassword'])->middleware('auth:sanctum');
});

Route::get('/user', function (Request $request) {
    return $request->user();
})->middleware('auth:sanctum');
