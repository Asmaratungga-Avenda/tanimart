<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Courier extends Model
{
    use SoftDeletes;

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

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class, 'kurir_id');
    }
}
