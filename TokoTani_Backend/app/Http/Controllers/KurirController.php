<?php

namespace App\Http\Controllers;

use App\Models\WilayahAntar;

class KurirController extends Controller
{
    private function jsonResponse($status, $code, $message, $data = null)
    {
        return response()->json([
            'status' => $status,
            'code' => (string) $code,
            'message' => $message,
            'data' => $data,
        ], (int) $code);
    }

    public function index()
    {
        $kurir = WilayahAntar::where('aktif', true)
            ->orderBy('tarif')
            ->get();

        return $this->jsonResponse(
            'sukses',
            200,
            'Daftar kurir/wilayah antar berhasil diambil',
            $kurir
        );
    }
}
