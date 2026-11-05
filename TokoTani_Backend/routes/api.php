<?php

use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\ProductController;
use Illuminate\Support\Facades\Route;

// Checkout & Orders
Route::post('/checkout', [CheckoutController::class, 'store']);
Route::get('/checkout/{id}', [CheckoutController::class, 'show']);
Route::get('/pesanan', [CheckoutController::class, 'index']);
Route::get('/pesanan/{id}', [CheckoutController::class, 'show']);
Route::get('/orders', [CheckoutController::class, 'index']);

// Kurir & Metode Pembayaran
Route::get('/kurir', [CheckoutController::class, 'couriers']);
Route::get('/couriers', [CheckoutController::class, 'couriers']);
Route::get('/metode-pembayaran', [CheckoutController::class, 'paymentMethods']);
Route::get('/payment-methods', [CheckoutController::class, 'paymentMethods']);

// Kategori & Produk
Route::get('/kategori', [ProductController::class, 'categories']);
Route::get('/categories', [ProductController::class, 'categories']);
Route::get('/produk', [ProductController::class, 'index']);
Route::get('/produk/{id}', [ProductController::class, 'show']);
Route::post('/produk', [ProductController::class, 'store']);
Route::put('/produk/{id}', [ProductController::class, 'update']);
Route::delete('/produk/{id}', [ProductController::class, 'destroy']);
