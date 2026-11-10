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
        $totalPesanan = Order::count();
        $totalPendapatan = Order::where('status', 'selesai')->sum('total_harga');
        $menungguPembayaran = Order::where('status', 'menunggu_pembayaran')->count();
        $diproses = Order::where('status', 'diproses')->count();

        return [
            Stat::make('Pendapatan', 'Rp ' . number_format($totalPendapatan, 0, ',', '.'))
                ->description('Total dari pesanan selesai')
                ->descriptionIcon('heroicon-m-banknotes')
                ->color('success'),
            Stat::make('Total Pesanan', $totalPesanan)
                ->description('Seluruh pesanan masuk')
                ->descriptionIcon('heroicon-m-shopping-cart')
                ->color('primary'),
            Stat::make('Pesanan Diproses', $diproses)
                ->description('Siap untuk dikirim')
                ->descriptionIcon('heroicon-m-truck')
                ->color('info'),
            Stat::make('Total Produk', $totalProduk)
                ->description('Produk dalam katalog')
                ->descriptionIcon('heroicon-m-squares-2x2')
                ->color('primary'),
        ];
    }
}
