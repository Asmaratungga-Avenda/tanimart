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
            ->filters([
                SelectFilter::make('status')
                    ->label('Status Pesanan')
                    ->options([
                        'menunggu_pembayaran' => 'Menunggu Pembayaran',
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

                Action::make('kirimPesanan')
                    ->label(fn (Order $record): string => match ($record->status) {
                        'diproses' => 'Kirim Pesanan',
                        'dikirim' => 'Sedang Dikirim',
                        'tiba' => 'Pesanan Tiba',
                        'selesai' => 'Selesai',
                        default => 'Kirim Pesanan',
                    })
                    ->icon(fn (Order $record): string => match ($record->status) {
                        'diproses' => 'heroicon-o-truck',
                        'dikirim' => 'heroicon-o-arrow-path',
                        'tiba' => 'heroicon-o-map-pin',
                        'selesai' => 'heroicon-o-check-circle',
                        default => 'heroicon-o-truck',
                    })
                    ->color(fn (Order $record): string => match ($record->status) {
                        'diproses' => 'success',
                        'dikirim' => 'primary',
                        'tiba' => 'warning',
                        'selesai' => 'gray',
                        default => 'gray',
                    })
                    ->visible(fn (Order $record): bool =>
                        in_array($record->status, ['diproses', 'dikirim', 'tiba', 'selesai'])
                    )
                    ->disabled(fn (Order $record): bool =>
                        $record->status !== 'diproses' || ! in_array($record->payment_status, ['paid', 'lunas'])
                    )
                    ->requiresConfirmation(fn (Order $record): bool => $record->status === 'diproses')
                    ->modalHeading('Kirim Pesanan')
                    ->modalDescription('Apakah Anda yakin ingin memproses dan mengirim pesanan ini sekarang?')
                    ->action(function (Order $record) {
                        if ($record->status !== 'diproses') {
                            Notification::make()
                                ->title('Pesanan tidak dalam status diproses.')
                                ->danger()
                                ->send();
                            return;
                        }

                        if (! in_array($record->payment_status, ['paid', 'lunas'])) {
                            Notification::make()
                                ->title('Pesanan belum lunas / dibayar.')
                                ->danger()
                                ->send();
                            return;
                        }

                        if ($record->dikirim_at !== null && $record->status === 'dikirim') {
                            Notification::make()
                                ->title('Pesanan ini sudah pernah dikirim.')
                                ->warning()
                                ->send();
                            return;
                        }

                        $record->update([
                            'status' => 'dikirim',
                            'dikirim_at' => now(),
                            'tiba_at' => null,
                        ]);

                        $seconds = (int) config('delivery.seconds', 5);
                        if (config('delivery.enabled', true)) {
                            DeliverOrderSimulation::dispatch($record->id)->delay(now()->addSeconds($seconds));
                        }

                        Notification::make()
                            ->title('Pesanan Berhasil Dikirim')
                            ->body("Pesanan #{$record->id} berhasil dikirim ke {$record->nama_penerima}. Simulasi tiba dalam {$seconds} detik.")
                            ->success()
                            ->send();
                    }),
            ])
            ->toolbarActions([]);
    }
}
