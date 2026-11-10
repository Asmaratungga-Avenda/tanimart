<?php

namespace App\Filament\Resources\Orders\Tables;

use App\Jobs\DeliverOrderSimulation;
use App\Models\Order;
use Filament\Actions\Action;
use Filament\Actions\ViewAction;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class OrdersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('id')
                    ->label('No. Pesanan')
                    ->formatStateUsing(fn ($state) => "#{$state}")
                    ->sortable()
                    ->searchable(),
                TextColumn::make('nama_penerima')
                    ->label('Nama Pelanggan')
                    ->searchable()
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Waktu Pesan')
                    ->dateTime('d M Y, H:i')
                    ->sortable(),
                TextColumn::make('payment_status')
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
                    })
                    ->sortable(),
                TextColumn::make('status')
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
                        'dibayar', 'diproses' => 'info',
                        'dikirim' => 'primary',
                        'tiba' => 'warning',
                        'selesai' => 'success',
                        'dibatalkan' => 'danger',
                        default => 'gray',
                    })
                    ->sortable(),
                TextColumn::make('total_harga')
                    ->label('Total Belanja')
                    ->money('IDR', locale: 'id')
                    ->sortable(),
                TextColumn::make('courier.nama')
                    ->label('Kurir')
                    ->sortable(),
                TextColumn::make('dikirim_at')
                    ->label('Waktu Kirim')
                    ->dateTime('d M Y, H:i')
                    ->placeholder('-')
                    ->sortable(),
                TextColumn::make('selesai_at')
                    ->label('Waktu Selesai')
                    ->dateTime('d M Y, H:i')
                    ->placeholder('-')
                    ->sortable(),
            ])
            ->defaultSort('created_at', 'desc')
            ->poll('10s')
            ->filters([
                SelectFilter::make('status')
                    ->label('Status Pesanan')
                    ->options([
                        'menunggu_pembayaran' => 'Menunggu Pembayaran',
                        'menunggu_konfirmasi' => 'Menunggu Konfirmasi',
                        'dibayar' => 'Dibayar',
                        'diproses' => 'Diproses',
                        'dikirim' => 'Dikirim',
                        'tiba' => 'Tiba',
                        'selesai' => 'Selesai',
                        'dibatalkan' => 'Dibatalkan',
                    ]),
                SelectFilter::make('payment_status')
                    ->label('Status Pembayaran')
                    ->options([
                        'lunas' => 'Lunas',
                        'belum_bayar' => 'Belum Bayar',
                    ]),
            ])
            ->recordActions([
                ViewAction::make()
                    ->label('Detail')
                    ->icon('heroicon-o-eye')
                    ->color('gray'),

                Action::make('prosesPesanan')
                    ->label('Proses Pesanan')
                    ->icon('heroicon-o-arrow-path')
                    ->color('info')
                    ->visible(fn (Order $record): bool => $record->status === 'dibayar')
                    ->requiresConfirmation()
                    ->modalHeading('Proses Pesanan')
                    ->modalDescription('Apakah Anda yakin ingin mulai memproses pesanan ini?')
                    ->action(function (Order $record) {
                        $record->update(['status' => 'diproses']);
                        Notification::make()->title('Pesanan Diproses')->success()->send();
                    }),

                Action::make('kirimPesanan')
                    ->label('Kirim Pesanan')
                    ->icon('heroicon-o-truck')
                    ->color('success')
                    ->visible(fn (Order $record): bool => $record->status === 'diproses')
                    ->requiresConfirmation()
                    ->modalHeading('Kirim Pesanan')
                    ->modalDescription('Apakah Anda yakin ingin mengirim pesanan ini?')
                    ->action(function (Order $record) {
                        $record->update([
                            'status' => 'dikirim',
                            'dikirim_at' => now(),
                        ]);

                        $seconds = (int) config('delivery.seconds', 5);
                        if (config('delivery.enabled', true)) {
                            DeliverOrderSimulation::dispatch($record->id)->delay(now()->addSeconds($seconds));
                        }

                        Notification::make()
                            ->title('Pesanan Dikirim')
                            ->body("Status akan berubah menjadi 'tiba' dalam {$seconds} detik.")
                            ->success()
                            ->send();
                    }),
            ])
            ->toolbarActions([]);
    }
}
