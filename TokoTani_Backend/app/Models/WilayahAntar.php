<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class WilayahAntar extends Model
{
    protected $table = 'couriers';

    protected $fillable = [
        'nama',
        'wilayah',
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

    public function pesanan(): HasMany
    {
        return $this->hasMany(Pesanan::class, 'kurir_id');
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'kurir_id');
    }
}
