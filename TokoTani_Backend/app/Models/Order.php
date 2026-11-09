<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    protected $fillable = [
        'nama_penerima',
        'alamat_penerima',
        'kurir_id',
        'payment_method_id',
        'subtotal',
        'ongkir',
        'total_harga',
        'status',
        'tanggal_antar',
        'idempotency_key',
    ];

    protected function casts(): array
    {
        return [
            'subtotal' => 'integer',
            'ongkir' => 'integer',
            'total_harga' => 'integer',
            'tanggal_antar' => 'date:Y-m-d',
        ];
    }

    protected static function booted(): void
    {
        static::updating(function (Order $order) {
            if ($order->isDirty('status')) {
                $oldStatus = $order->getOriginal('status');
                $newStatus = $order->status;

                if ($newStatus === 'dibatalkan' && $oldStatus !== 'dibatalkan') {
                    foreach ($order->items as $item) {
                        $product = $item->product;
                        if ($product) {
                            $product->increment('stok', $item->quantity);
                            if ($product->stok > 0 && ! $product->tersedia) {
                                $product->tersedia = true;
                                $product->save();
                            }
                        }
                    }
                }
            }
        });
    }

    public function courier(): BelongsTo
    {
        return $this->belongsTo(Courier::class, 'kurir_id');
    }

    public function kurir(): BelongsTo
    {
        return $this->belongsTo(Courier::class, 'kurir_id');
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    public function metodePembayaran(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class);
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
