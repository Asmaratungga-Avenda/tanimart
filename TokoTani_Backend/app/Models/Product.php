<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    // Melindungi kolom id agar tidak bisa diisi sembarang, sisanya mass-assignable
    protected $guarded = ['id'];

    // Menambahkan field virtual nama_produk agar serasi dengan kebutuhan Frontend
    protected $appends = ['nama_produk'];

    public function getNamaProdukAttribute()
    {
        return $this->attributes['nama'] ?? null;
    }
}
