<?php

namespace App\Models;

use App\Traits\HandleImageStorage;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Category extends Model
{
    use HandleImageStorage;

    protected $appends = ['gambar_url'];

    protected $fillable = [
        'nama_kategori',
        'gambar',
    ];

    protected static function booted(): void
    {
        static::deleted(function (Category $category) {
            $category->deleteImage($category->gambar);
        });
    }

    public function getGambarUrlAttribute(): ?string
    {
        return $this->getFullImageUrl($this->gambar);
    }
}

