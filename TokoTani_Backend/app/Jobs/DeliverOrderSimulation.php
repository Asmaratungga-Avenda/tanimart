<?php

namespace App\Jobs;

use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;

class DeliverOrderSimulation implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $orderId;

    public function __construct(int $orderId)
    {
        $this->orderId = $orderId;
    }

    public function handle(): void
    {
        if (! config('delivery.enabled', true)) {
            Log::info('DeliverOrderSimulation: delivery simulation is disabled, skipping auto arrival', [
                'order_id' => $this->orderId,
            ]);
            return;
        }

        $order = Order::find($this->orderId);

        if (! $order) {
            Log::warning('DeliverOrderSimulation: order not found', ['order_id' => $this->orderId]);
            return;
        }

        // Hanya terapkan simulasi jika order masih berstatus dikirim.
        if ($order->status !== 'dikirim') {
            Log::info('DeliverOrderSimulation: order tidak dalam status dikirim, dilewati', [
                'order_id' => $this->orderId,
                'status' => $order->status,
            ]);
            return;
        }

        $order->update([
            'status' => 'tiba',
            'tiba_at' => Carbon::now(),
        ]);

        Log::info('DeliverOrderSimulation: order berubah menjadi tiba', [
            'order_id' => $this->orderId,
        ]);
    }
}
