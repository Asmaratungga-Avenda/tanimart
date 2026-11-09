<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Order;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
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
                    ->columns(3)
                    ->components([
                        TextEntry::make('id')
                            ->label('Nomor Pesanan')
                            ->formatStateUsing(fn ($state) => "#{$state}"),
                        TextEntry::make('created_at')
                            ->label('Tanggal Pesanan')
                            ->dateTime('d F Y, H:i'),
                        TextEntry::make('payment_status')
                            ->label('Status Pembayaran')
                            ->badge()
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'lunas', 'paid' => 'Lunas',
                                'belum_bayar', 'unpaid', null => 'Belum Bayar',
                                default => ucfirst((string) $state),
                            })
                            ->color(fn (?string $state): string => match ($state) {
                                'lunas', 'paid' => 'success',
                                'belum_bayar', 'unpaid', null => 'warning',
                                default => 'gray',
                            }),
                        TextEntry::make('status')
                            ->label('Status Pesanan')
                            ->badge()
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'menunggu_pembayaran' => 'Menunggu Pembayaran',
                                'menunggu_konfirmasi' => 'Menunggu Konfirmasi',
                                'dibayar' => 'Dibayar',
                                'diproses' => 'Diproses',
                                'dikirim' => 'Dikirim',
                                'tiba' => 'Tiba',
                                'selesai' => 'Selesai',
                                'dibatalkan' => 'Dibatalkan',
                                default => ucfirst((string) $state),
                            })
                            ->color(fn (?string $state): string => match ($state) {
                                'menunggu_pembayaran', 'menunggu_konfirmasi' => 'warning',
                                'dibayar' => 'info',
                                'diproses' => 'info',
                                'dikirim' => 'primary',
                                'tiba' => 'warning',
                                'selesai' => 'success',
                                'dibatalkan' => 'danger',
                                default => 'gray',
                            }),
                    ]),

                Section::make('Informasi Customer')
                    ->columns(2)
                    ->components([
                        Group::make([
                            TextEntry::make('nama_penerima')
                                ->label('Nama'),
                            TextEntry::make('customer.phone')
                                ->label('Nomor Telepon')
                                ->default('-'),
                        ]),
                        Group::make([
                            TextEntry::make('alamat_penerima')
                                ->label('Alamat Pengiriman')
                                ->columnSpanFull(),
                        ]),
                    ]),

                Section::make('Produk Pesanan')
                    ->columns(6)
                    ->components([
                        RepeatableEntry::make('items')
                            ->label('')
                            ->columns(6)
                            ->components([
                                ImageEntry::make('product.gambar')
                                    ->label('Foto Produk')
                                    ->disk('public')
                                    ->height(48)
                                    ->defaultImageUrl(null),
                                TextEntry::make('product.nama')
                                    ->label('Nama Produk')
                                    ->weight('bold'),
                                TextEntry::make('harga_satuan')
                                    ->label('Harga Satuan')
                                    ->money('IDR', locale: 'id'),
                                TextEntry::make('quantity')
                                    ->label('Jumlah'),
                                TextEntry::make('subtotal')
                                    ->label('Subtotal')
                                    ->money('IDR', locale: 'id')
                                    ->weight('bold'),
                            ]),
                    ]),

                Section::make('Ringkasan Pembayaran')
                    ->columns(3)
                    ->components([
                        TextEntry::make('total_harga')
                            ->label('Total Pembayaran')
                            ->money('IDR', locale: 'id')
                            ->weight('bold'),
                        TextEntry::make('paymentMethod.nama')
                            ->label('Metode Pembayaran'),
                        TextEntry::make('payment_status')
                            ->label('Informasi Pembayaran')
                            ->formatStateUsing(fn (?string $state): string => match ($state) {
                                'lunas', 'paid' => 'Lunas / Sudah Dibayar',
                                'menunggu_verifikasi' => 'Menunggu Verifikasi',
                                'belum_bayar', 'unpaid', null => 'Belum Bayar',
                                default => ucfirst((string) $state),
                            }),
                    ]),
            ]);
    }
}
