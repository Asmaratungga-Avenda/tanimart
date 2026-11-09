<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DetailPesanan extends Model
{
    protected $table = 'order_items';

    protected $fillable = [
        'order_id',
        'product_id',
        'nama_produk',
        'quantity',
        'harga_satuan',
        'subtotal',
    ];

    protected function casts(): array
    {
        return [
            'order_id' => 'integer',
            'product_id' => 'integer',
            'quantity' => 'integer',
            'harga_satuan' => 'integer',
            'subtotal' => 'integer',
        ];
    }

    public function pesanan(): BelongsTo
    {
        return $this->belongsTo(Pesanan::class, 'order_id');
    }

    public function order(): BelongsTo
    {
        return $this->belongsTo(Order::class, 'order_id');
    }

    public function produk(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }
}
