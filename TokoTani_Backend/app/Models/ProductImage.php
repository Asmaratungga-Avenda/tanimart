<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ProductImage extends Model
{
    protected $appends = ['url'];

    protected $fillable = [
        'product_id',
        'gambar',
        'is_thumbnail',
        'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'is_thumbnail' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function getUrlAttribute(): string
    {
        if (Str::startsWith($this->gambar, ['http://', 'https://'])) {
            return $this->gambar;
        }

        return Storage::disk('public')->url($this->gambar);
    }
}
