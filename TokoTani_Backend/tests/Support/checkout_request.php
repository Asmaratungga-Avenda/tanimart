<?php

use Illuminate\Contracts\Http\Kernel;
use Illuminate\Http\Request;

require __DIR__.'/../../vendor/autoload.php';

$app = require __DIR__.'/../../bootstrap/app.php';

$payload = json_decode(base64_decode($argv[1] ?? ''), true) ?: [];
$idempotencyKey = $argv[2] ?? '';
$pelangganId = $argv[3] ?? '1';
$barrier = $argv[4] ?? null;
$token = $argv[5] ?? '';

if ($barrier !== null) {
    $deadline = microtime(true) + 10;

    while (! file_exists($barrier) && microtime(true) < $deadline) {
        usleep(10000);
    }
}

$request = Request::create(
    '/api/checkout',
    'POST',
    [],
    [],
    [],
    [
        'CONTENT_TYPE' => 'application/json',
        'HTTP_ACCEPT' => 'application/json',
        'HTTP_X_KUNCI_IDEMPOTEN' => $idempotencyKey,
        'HTTP_AUTHORIZATION' => 'Bearer '.$token,
    ],
    json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES)
);

$kernel = $app->make(Kernel::class);
$response = $kernel->handle($request);

fwrite(STDOUT, "\n__CHECKOUT_RESULT__".json_encode([
    'http_status' => $response->getStatusCode(),
    'body' => json_decode($response->getContent(), true),
]));

$kernel->terminate($request, $response);
