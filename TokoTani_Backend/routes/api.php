<?php

use App\Http\Controllers\CartController;
use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\KurirController;
use App\Http\Controllers\ProductController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:5,1');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::get('/kurir', [CheckoutController::class, 'couriers']);
Route::get('/couriers', [CheckoutController::class, 'couriers']);
Route::get('/metode-pembayaran', [CheckoutController::class, 'paymentMethods']);
Route::get('/payment-methods', [CheckoutController::class, 'paymentMethods']);
Route::get('/wilayah', [KurirController::class, 'index']);

Route::get('/banners', [ProductController::class, 'banners']);
Route::get('/banner', [ProductController::class, 'banners']);
Route::get('/kategori', [ProductController::class, 'categories']);
Route::get('/categories', [ProductController::class, 'categories']);
Route::get('/produk', [ProductController::class, 'index']);
Route::get('/produk/{id}', [ProductController::class, 'show']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/keranjang', [CartController::class, 'index']);
    Route::post('/keranjang', [CartController::class, 'store']);
    Route::put('/keranjang/{id}', [CartController::class, 'update']);
    Route::delete('/keranjang/{id}', [CartController::class, 'destroy']);
    Route::delete('/keranjang', [CartController::class, 'clear']);

    Route::get('/cart', [CartController::class, 'index']);
    Route::post('/cart', [CartController::class, 'store']);
    Route::put('/cart/{id}', [CartController::class, 'update']);
    Route::delete('/cart/{id}', [CartController::class, 'destroy']);

    Route::post('/checkout', [CheckoutController::class, 'store']);
    Route::get('/checkout/{id}', [CheckoutController::class, 'show']);
    Route::get('/pesanan', [CheckoutController::class, 'index']);
    Route::get('/pesanan/{id}', [CheckoutController::class, 'show']);
    Route::post('/pesanan/{id}/pembayaran', [CheckoutController::class, 'pembayaran']);
    Route::post('/pesanan/{id}/selesai', [CheckoutController::class, 'selesai']);
    Route::get('/orders', [CheckoutController::class, 'index']);
    Route::get('/orders/{id}', [CheckoutController::class, 'show']);

    Route::middleware('admin')->group(function () {
        Route::patch('/checkout/{id}/status', [CheckoutController::class, 'updateStatus']);
        Route::patch('/pesanan/{id}/status', [CheckoutController::class, 'updateStatus']);
        Route::post('/pesanan/{id}/kirim', [CheckoutController::class, 'kirim']);
        Route::patch('/orders/{id}/status', [CheckoutController::class, 'updateStatus']);
        Route::post('/produk', [ProductController::class, 'store']);
        Route::put('/produk/{id}', [ProductController::class, 'update']);
        Route::delete('/produk/{id}', [ProductController::class, 'destroy']);
        Route::delete('/kurir/{id}', [KurirController::class, 'destroy']);
        Route::delete('/couriers/{id}', [KurirController::class, 'destroy']);
        Route::delete('/wilayah/{id}', [KurirController::class, 'destroy']);
    });
});
