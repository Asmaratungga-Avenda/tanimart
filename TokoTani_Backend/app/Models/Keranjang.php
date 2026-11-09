<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Keranjang extends Model
{
    protected $table = 'keranjang';

    protected $fillable = [
        'pelanggan_id',
        'product_id',
        'jumlah',
    ];

    protected $appends = [
        'subtotal',
    ];

    protected function casts(): array
    {
        return [
            'pelanggan_id' => 'integer',
            'product_id' => 'integer',
            'jumlah' => 'integer',
        ];
    }

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pelanggan_id');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function produk(): BelongsTo
    {
        return $this->belongsTo(Product::class, 'product_id');
    }

    public function getSubtotalAttribute(): int
    {
        return ($this->product?->harga ?? 0) * $this->jumlah;
    }
}
