<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    protected $fillable = [
        'pelanggan_id',
        'nama_penerima',
        'alamat_penerima',
        'kurir_id',
        'payment_method_id',
        'subtotal',
        'ongkir',
        'total_harga',
        'status',
        'tanggal_antar',
        'tanggal_pengantaran',
        'slot_pengantaran',
        'idempotency_key',
    ];

    protected function casts(): array
    {
        return [
            'pelanggan_id' => 'integer',
            'subtotal' => 'integer',
            'ongkir' => 'integer',
            'total_harga' => 'integer',
            'tanggal_antar' => 'date:Y-m-d',
            'tanggal_pengantaran' => 'date:Y-m-d',
        ];
    }

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pelanggan_id');
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
