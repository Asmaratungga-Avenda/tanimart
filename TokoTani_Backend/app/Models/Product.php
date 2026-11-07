<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Product extends Model
{
    use HasFactory;

    // Melindungi kolom id agar tidak bisa diisi sembarang, sisanya mass-assignable
    protected $guarded = ['id'];

    protected function casts(): array
    {
        return [
            'harga' => 'integer',
            'stok' => 'integer',
            'category_id' => 'integer',
            'tersedia' => 'boolean',
            'mudah_rusak' => 'boolean',
        ];
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function orderDetails(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
