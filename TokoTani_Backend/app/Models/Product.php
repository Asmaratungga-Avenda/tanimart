<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Product extends Model
{
    use HasFactory;

    protected $appends = ['gambar_url'];

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
            'gambar' => 'string',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (Product $product) {
            if ($product->stok <= 0) {
                $product->tersedia = false;
            }

            if (empty($product->category_id) && ! empty($product->kategori)) {
                $category = Category::where('nama_kategori', $product->kategori)->first();
                if ($category) {
                    $product->category_id = $category->id;
                }
            }
        });
    }

    public function getGambarUrlAttribute(): ?string
    {
        if (! $this->gambar) {
            return null;
        }

        if (Str::startsWith($this->gambar, ['http://', 'https://'])) {
            return $this->gambar;
        }

        return Storage::disk('public')->url($this->gambar);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function productImages(): HasMany
    {
        return $this->hasMany(ProductImage::class)->orderBy('sort_order', 'asc');
    }

    public function orderItems(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function orderDetails(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function carts(): HasMany
    {
        return $this->hasMany(Cart::class);
    }
}
