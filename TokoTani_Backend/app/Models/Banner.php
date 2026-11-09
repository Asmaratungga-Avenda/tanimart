<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Banner extends Model
{
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

    public function getUrlAttribute(): string
    {
        if (Str::startsWith($this->gambar, ['http://', 'https://'])) {
            return $this->gambar;
        }

        return Storage::disk('public')->url($this->gambar);
    }

    public function scopeAktif($query)
    {
        return $query->where('aktif', true)->orderBy('urutan', 'asc');
    }
}
