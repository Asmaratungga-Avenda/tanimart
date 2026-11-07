<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Courier extends Model
{
    protected $fillable = [
        'nama',
        'tarif',
        'aktif',
    ];

    protected function casts(): array
    {
        return [
            'tarif' => 'integer',
            'aktif' => 'boolean',
        ];
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'kurir_id');
    }
}

