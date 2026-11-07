<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Product;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class TaniMartStatsOverview extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $totalProduk = Product::count();
        $produkAktif = Product::where('tersedia', true)->count();
        $pesananMenunggu = Order::where('status', 'menunggu_pembayaran')->count();
        $pesananSelesai = Order::where('status', 'selesai')->count();
        $totalPenjualan = Order::where('status', '!=', 'dibatalkan')->sum('total_harga');

        return [
            Stat::make('Total Produk Aktif', $produkAktif . ' / ' . $totalProduk)
                ->description('Produk siap dipesan')
                ->color('success'),
            Stat::make('Pesanan Menunggu', $pesananMenunggu)
                ->description('Menunggu pembayaran')
                ->color('warning'),
            Stat::make('Pesanan Selesai', $pesananSelesai)
                ->description('Transaksi berhasil')
                ->color('info'),
            Stat::make('Total Penjualan', 'Rp ' . number_format($totalPenjualan, 0, ',', '.'))
                ->description('Pendapatan pesanan aktif')
                ->color('success'),
        ];
    }
}
