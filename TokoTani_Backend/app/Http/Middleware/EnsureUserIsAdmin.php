<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserIsAdmin
{
    public function handle(Request $request, Closure $next): Response
    {
        if ($request->user()?->role !== 'admin') {
            return response()->json([
                'status' => 'gagal',
                'code' => '403',
                'message' => 'Akses hanya tersedia untuk admin.',
            ], 403);
        }

        return $next($request);
    }
}
