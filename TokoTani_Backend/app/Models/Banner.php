<?php

namespace App\Models;

use App\Traits\HandleImageStorage;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Banner extends Model
{
    use HandleImageStorage;

    protected $appends = ['url'];

    protected $fillable = [
        'judul',
        'gambar',
        'link',
        'urutan',
        'aktif',
    ];

    protected function casts(): array
    {
        return [
            'urutan' => 'integer',
            'aktif' => 'boolean',
        ];
    }

    protected static function booted(): void
    {
        static::deleted(function (Banner $banner) {
            $banner->deleteImage($banner->gambar);
        });
    }

    public function getUrlAttribute(): string
    {
        return $this->getFullImageUrl($this->gambar) ?? '';
    }

    public function scopeAktif($query)
    {
        return $query->where('aktif', true)->orderBy('urutan', 'asc');
    }
}
