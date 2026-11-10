<?php

namespace App\Filament\Resources\Orders\Pages;

use App\Filament\Resources\Orders\OrderResource;
use App\Jobs\DeliverOrderSimulation;
use App\Models\Order;
use Filament\Actions\Action;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;

class ViewOrder extends ViewRecord
{
    protected static string $resource = OrderResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('konfirmasiPembayaran')
                ->label('Konfirmasi Pembayaran')
                ->icon('heroicon-o-check-badge')
                ->color('success')
                ->visible(fn (): bool => $this->record->status === 'menunggu_konfirmasi')
                ->requiresConfirmation()
                ->action(function () {
                    $this->record->update([
                        'status' => 'dibayar',
                        'payment_status' => 'lunas',
                    ]);
                    Notification::make()->title('Pembayaran Dikonfirmasi')->success()->send();
                }),

            Action::make('prosesPesanan')
                ->label('Proses Pesanan')
                ->icon('heroicon-o-arrow-path')
                ->color('info')
                ->visible(fn (): bool => $this->record->status === 'dibayar')
                ->requiresConfirmation()
                ->action(function () {
                    $this->record->update(['status' => 'diproses']);
                    Notification::make()->title('Pesanan Diproses')->success()->send();
                }),

            Action::make('kirimPesanan')
                ->label('Kirim Pesanan')
                ->icon('heroicon-o-truck')
                ->color('success')
                ->visible(fn (): bool => $this->record->status === 'diproses')
                ->requiresConfirmation()
                ->action(function () {
                    $this->record->update([
                        'status' => 'dikirim',
                        'dikirim_at' => now(),
                    ]);

                    $seconds = (int) config('delivery.seconds', 5);
                    if (config('delivery.enabled', true)) {
                        DeliverOrderSimulation::dispatch($this->record->id)->delay(now()->addSeconds($seconds));
                    }

                    Notification::make()
                        ->title('Pesanan Dikirim')
                        ->body("Status akan berubah menjadi 'tiba' dalam {$seconds} detik.")
                        ->success()
                        ->send();
                }),
        ];
    }
}

