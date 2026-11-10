<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\Storage;

Route::get('/', function () {
    return redirect('/admin/login');
});

Route::match(['GET', 'OPTIONS'], '/storage/{path}', function ($path) {
    $headers = [
        'Access-Control-Allow-Origin' => '*',
        'Access-Control-Allow-Methods' => 'GET, OPTIONS',
        'Access-Control-Allow-Headers' => '*',
        'Cache-Control' => 'public, max-age=86400',
    ];

    if (request()->isMethod('OPTIONS')) {
        return response()->noContent(204, $headers);
    }

    $disk = Storage::disk('public');
    abort_unless($disk->exists($path), 404);

    return $disk->response($path, null, $headers);
})->where('path', '.*');
