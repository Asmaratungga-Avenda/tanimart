<?php

use App\Http\Controllers\CheckoutController;
use App\Http\Controllers\KeranjangController;
use App\Http\Controllers\KurirController;
use App\Http\Controllers\ProductController;
use Illuminate\Support\Facades\Route;

// Keranjang Belanja
Route::delete('/keranjang', [KeranjangController::class, 'clear']);
Route::get('/keranjang', [KeranjangController::class, 'index']);
Route::post('/keranjang', [KeranjangController::class, 'store']);
Route::put('/keranjang/{id}', [KeranjangController::class, 'update']);
Route::delete('/keranjang/{id}', [KeranjangController::class, 'destroy']);

// Checkout & Orders
Route::post('/checkout', [CheckoutController::class, 'store']);
Route::get('/checkout/{id}', [CheckoutController::class, 'show']);
Route::get('/pesanan', [CheckoutController::class, 'index']);
Route::get('/pesanan/{id}', [CheckoutController::class, 'show']);
Route::patch('/pesanan/{id}/status', [CheckoutController::class, 'updateStatus']);
Route::get('/orders', [CheckoutController::class, 'index']);

// Kurir & Metode Pembayaran
Route::get('/kurir', [KurirController::class, 'index']);
Route::get('/couriers', [KurirController::class, 'index']);
Route::get('/wilayah', [KurirController::class, 'index']);
Route::delete('/kurir/{id}', [KurirController::class, 'destroy']);
Route::delete('/couriers/{id}', [KurirController::class, 'destroy']);
Route::delete('/wilayah/{id}', [KurirController::class, 'destroy']);
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
