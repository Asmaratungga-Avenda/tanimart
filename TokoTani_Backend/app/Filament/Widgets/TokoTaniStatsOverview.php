<?php

namespace App\Filament\Widgets;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class TokoTaniStatsOverview extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $totalProduk = Product::count();
        $totalKategori = Category::count();
        $totalPesanan = Order::count();
        $menungguPembayaran = Order::where('status', 'menunggu_pembayaran')->count();
        $diproses = Order::where('status', 'diproses')->count();
        $dikirim = Order::where('status', 'dikirim')->count();
        $selesai = Order::where('status', 'selesai')->count();

        return [
            Stat::make('Total Produk', $totalProduk)
                ->description('Semua produk dalam katalog')
                ->color('primary'),
            Stat::make('Total Kategori', $totalKategori)
                ->description('Kategori produk tersedia')
                ->color('info'),
            Stat::make('Total Pesanan', $totalPesanan)
                ->description('Seluruh pesanan masuk')
                ->color('primary'),
            Stat::make('Menunggu Pembayaran', $menungguPembayaran)
                ->description('Belum dibayar pelanggan')
                ->color('warning'),
            Stat::make('Diproses', $diproses)
                ->description('Siap untuk dikirim')
                ->color('info'),
            Stat::make('Dikirim', $dikirim)
                ->description('Sedang dalam pengiriman')
                ->color('primary'),
            Stat::make('Selesai', $selesai)
                ->description('Transaksi berhasil')
                ->color('success'),
        ];
    }
}
