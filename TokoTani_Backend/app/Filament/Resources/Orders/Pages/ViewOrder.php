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
            Action::make('kirimPesanan')
                ->label('Kirim Pesanan')
                ->icon('heroicon-o-truck')
                ->color('success')
                ->visible(fn (): bool =>
                    in_array($this->record->payment_status, ['paid', 'lunas']) &&
                    $this->record->status === 'diproses'
                )
                ->requiresConfirmation()
                ->modalHeading('Kirim Pesanan')
                ->modalDescription('Apakah Anda yakin ingin memproses dan mengirim pesanan ini sekarang?')
                ->action(function () {
                    /** @var Order $order */
                    $order = $this->record;

                    if (! in_array($order->payment_status, ['paid', 'lunas']) || $order->status !== 'diproses') {
                        Notification::make()
                            ->title('Pesanan tidak memenuhi syarat untuk dikirim.')
                            ->danger()
                            ->send();
                        return;
                    }

                    if ($order->dikirim_at !== null && $order->status === 'dikirim') {
                        Notification::make()
                            ->title('Pesanan ini sudah pernah dikirim.')
                            ->warning()
                            ->send();
                        return;
                    }

                    $order->update([
                        'status' => 'dikirim',
                        'dikirim_at' => now(),
                    ]);

                    $seconds = (int) config('delivery.seconds', 5);
                    if (config('delivery.enabled', true)) {
                        DeliverOrderSimulation::dispatch($order->id)->delay(now()->addSeconds($seconds));
                    }

                    Notification::make()
                        ->title('Pesanan Berhasil Dikirim')
                        ->body("Pesanan #{$order->id} sedang dikirim. Estimasi tiba dalam {$seconds} detik.")
                        ->success()
                        ->send();
                }),
        ];
    }
}

