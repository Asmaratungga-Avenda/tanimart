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

    public function destroy($id)
    {
        $kurir = WilayahAntar::find($id);

        if (! $kurir) {
            return $this->jsonResponse(
                'gagal',
                404,
                'Kurir/wilayah antar tidak ditemukan'
            );
        }

        // Soft delete menjaga foreign key orders.kurir_id tetap utuh. Relasi
        // pesanan memakai withTrashed() sehingga riwayat lama tetap dapat
        // menampilkan nama, wilayah, dan tarif kurir saat transaksi terjadi.
        $dipakaiPadaPesanan = $kurir->orders()->exists();

        $kurir->delete();

        return $this->jsonResponse(
            'sukses',
            200,
            'Kurir/wilayah antar berhasil dihapus',
            [
                'id' => (int) $kurir->id,
                'dipakai_pada_pesanan' => $dipakaiPadaPesanan,
            ]
        );
    }
}
