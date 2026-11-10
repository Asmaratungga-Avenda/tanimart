<?php

use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Penanganan CORS untuk file statis di storage
Route::match(['GET', 'OPTIONS'], '/storage/{path}', function ($path) {
    $filePath = storage_path('app/public/' . $path);
    if (!file_exists($filePath)) abort(404);

    $mimeType = mime_content_type($filePath);
    return response()->file($filePath, [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => '*',
        'Content-Type' => $mimeType,
    ]);
})->where('path', '.*');
