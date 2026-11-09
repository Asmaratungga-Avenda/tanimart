<?php

use App\Http\Controllers\CartController;
use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\ProductController;
use Illuminate\Support\Facades\Route;

// Keranjang Belanja (Cart)
Route::get('/keranjang', [CartController::class, 'index']);
Route::post('/keranjang', [CartController::class, 'store']);
Route::put('/keranjang/{id}', [CartController::class, 'update']);
Route::delete('/keranjang/{id}', [CartController::class, 'destroy']);
Route::delete('/keranjang', [CartController::class, 'clear']);

Route::get('/cart', [CartController::class, 'index']);
Route::post('/cart', [CartController::class, 'store']);
Route::put('/cart/{id}', [CartController::class, 'update']);
Route::delete('/cart/{id}', [CartController::class, 'destroy']);

// Checkout & Orders
Route::post('/checkout', [CheckoutController::class, 'store']);
Route::get('/checkout/{id}', [CheckoutController::class, 'show']);
Route::patch('/checkout/{id}/status', [CheckoutController::class, 'updateStatus']);
Route::get('/pesanan', [CheckoutController::class, 'index']);
Route::get('/pesanan/{id}', [CheckoutController::class, 'show']);
Route::patch('/pesanan/{id}/status', [CheckoutController::class, 'updateStatus']);
Route::post('/pesanan/{id}/pembayaran', [CheckoutController::class, 'pembayaran']);
Route::post('/pesanan/{id}/kirim', [CheckoutController::class, 'kirim']);
Route::post('/pesanan/{id}/selesai', [CheckoutController::class, 'selesai']);
Route::get('/orders', [CheckoutController::class, 'index']);
Route::get('/orders/{id}', [CheckoutController::class, 'show']);
Route::patch('/orders/{id}/status', [CheckoutController::class, 'updateStatus']);

// Kurir & Metode Pembayaran
Route::get('/kurir', [CheckoutController::class, 'couriers']);
Route::get('/couriers', [CheckoutController::class, 'couriers']);
Route::get('/metode-pembayaran', [CheckoutController::class, 'paymentMethods']);
Route::get('/payment-methods', [CheckoutController::class, 'paymentMethods']);

// Banner Promo
Route::get('/banners', [ProductController::class, 'banners']);
Route::get('/banner', [ProductController::class, 'banners']);

// Kategori & Produk
Route::get('/kategori', [ProductController::class, 'categories']);
Route::get('/categories', [ProductController::class, 'categories']);
Route::get('/produk', [ProductController::class, 'index']);
Route::get('/produk/{id}', [ProductController::class, 'show']);
Route::post('/produk', [ProductController::class, 'store']);
Route::put('/produk/{id}', [ProductController::class, 'update']);
Route::delete('/produk/{id}', [ProductController::class, 'destroy']);
