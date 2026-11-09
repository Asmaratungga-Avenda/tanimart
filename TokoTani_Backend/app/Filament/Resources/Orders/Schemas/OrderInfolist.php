<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Order;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Group;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OrderInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Informasi Pesanan')
                    ->icon('heroicon-o-shopping-bag')
                    ->columns(3)
                    ->components([
                        TextEntry::make('id')
                            ->label('Nomor Pesanan')
                            ->formatStateUsing(fn ($state) => "#{$state}"),
                        TextEntry::make('created_at')
                            ->label('Waktu Pemesanan')
                            ->dateTime('d F Y, H:i:s'),
                        TextEntry::make('status')
                            ->label('Status Pesanan')
                            ->badge()
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'menunggu_pembayaran' => 'Menunggu Pembayaran',
                                'diproses' => 'Diproses',
                                'dikirim' => 'Dikirim',
                                'tiba' => 'Tiba',
                                'selesai' => 'Selesai',
                                'dibatalkan' => 'Dibatalkan',
                                default => ucfirst((string) $state),
                            })
                            ->color(fn (?string $state): string => match ($state) {
                                'menunggu_pembayaran' => 'warning',
                                'diproses' => 'info',
                                'dikirim' => 'primary',
                                'tiba' => 'warning',
                                'selesai' => 'success',
                                'dibatalkan' => 'danger',
                                default => 'gray',
                            }),
                        TextEntry::make('subtotal')
                            ->label('Subtotal Produk')
                            ->money('IDR', locale: 'id'),
                        TextEntry::make('ongkir')
                            ->label('Ongkos Kirim')
                            ->money('IDR', locale: 'id'),
                        TextEntry::make('total_harga')
                            ->label('Total Pembayaran')
                            ->money('IDR', locale: 'id')
                            ->weight('bold'),
                    ]),

                Section::make('Informasi Pelanggan & Pengiriman')
                    ->icon('heroicon-o-user')
                    ->columns(2)
                    ->components([
                        Group::make([
                            TextEntry::make('nama_penerima')
                                ->label('Nama Penerima / Pelanggan'),
                            TextEntry::make('customer.email')
                                ->label('Email Pelanggan')
                                ->default('-'),
                            TextEntry::make('customer.phone')
                                ->label('Nomor Telepon')
                                ->default('-'),
                        ]),
                        Group::make([
                            TextEntry::make('alamat_penerima')
                                ->label('Alamat Lengkap Pengiriman'),
                            TextEntry::make('courier.nama')
                                ->label('Kurir Pengiriman'),
                            TextEntry::make('tanggal_antar')
                                ->label('Slot / Tanggal Pengantaran')
                                ->date('d F Y'),
                            TextEntry::make('dikirim_at')
                                ->label('Waktu Dikirim')
                                ->dateTime('d F Y, H:i:s')
                                ->placeholder('-'),
                            TextEntry::make('tiba_at')
                                ->label('Waktu Tiba (Estimasi / Realisasi)')
                                ->dateTime('d F Y, H:i:s')
                                ->placeholder('-'),
                        ]),
                    ]),

                Section::make('Rincian Pembayaran')
                    ->icon('heroicon-o-credit-card')
                    ->columns(3)
                    ->components([
                        TextEntry::make('paymentMethod.nama')
                            ->label('Metode Pembayaran'),
                        TextEntry::make('payment_status')
                            ->label('Status Pembayaran')
                            ->badge()
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'lunas', 'paid' => 'Lunas / Paid',
                                'belum_bayar', 'unpaid', null => 'Belum Bayar / Unpaid',
                                default => ucfirst((string) $state),
                            })
                            ->color(fn (?string $state): string => match ($state) {
                                'lunas', 'paid' => 'success',
                                'belum_bayar', 'unpaid', null => 'warning',
                                default => 'gray',
                            }),
                        TextEntry::make('idempotency_key')
                            ->label('Referensi / Idempotency Key')
                            ->default('-'),
                        TextEntry::make('updated_at')
                            ->label('Waktu Pembaharuan Terakhir')
                            ->dateTime('d F Y, H:i:s'),
                    ]),

                Section::make('Daftar Produk yang Dipesan')
                    ->icon('heroicon-o-shopping-cart')
                    ->components([
                        RepeatableEntry::make('items')
                            ->label('')
                            ->columns(6)
                            ->components([
                                ImageEntry::make('product.gambar')
                                    ->label('Foto Produk')
                                    ->disk('public')
                                    ->circular()
                                    ->defaultImageUrl(url('/storage/products/default.jpg')),
                                TextEntry::make('product.nama')
                                    ->label('Nama Produk')
                                    ->weight('bold'),
                                TextEntry::make('product.satuan_jual')
                                    ->label('Satuan')
                                    ->default('item'),
                                TextEntry::make('quantity')
                                    ->label('Kuantitas'),
                                TextEntry::make('harga_satuan')
                                    ->label('Harga Satuan')
                                    ->money('IDR', locale: 'id'),
                                TextEntry::make('subtotal')
                                    ->label('Subtotal')
                                    ->money('IDR', locale: 'id')
                                    ->weight('bold'),
                            ]),
                    ]),
            ]);
    }
}

