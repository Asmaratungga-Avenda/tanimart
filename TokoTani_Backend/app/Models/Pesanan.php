<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Pesanan extends Model
{
    public const STATUS_MENUNGGU_PEMBAYARAN = 'menunggu_pembayaran';

    public const STATUS_MENUNGGU_KONFIRMASI = 'menunggu_konfirmasi';

    public const STATUS_DIBAYAR = 'dibayar';

    public const STATUS_DIPROSES = 'diproses';

    public const STATUS_DIKIRIM = 'dikirim';

    public const STATUS_SELESAI = 'selesai';

    public const STATUS_DIBATALKAN = 'dibatalkan';

    protected $table = 'orders';

    protected $fillable = [
        'pelanggan_id',
        'nama_penerima',
        'alamat_penerima',
        'kurir_id',
        'payment_method_id',
        'subtotal',
        'ongkir',
        'total_harga',
        'status',
        'tanggal_antar',
        'tanggal_pengantaran',
        'slot_pengantaran',
        'idempotency_key',
        'idempotency_request_hash',
    ];

    protected $hidden = [
        'idempotency_request_hash',
    ];

    protected $appends = [
        'alamat',
        'total',
    ];

    protected function casts(): array
    {
        return [
            'pelanggan_id' => 'integer',
            'kurir_id' => 'integer',
            'payment_method_id' => 'integer',
            'subtotal' => 'integer',
            'ongkir' => 'integer',
            'total_harga' => 'integer',
            'tanggal_antar' => 'date:Y-m-d',
            'tanggal_pengantaran' => 'date:Y-m-d',
        ];
    }

    public function pelanggan(): BelongsTo
    {
        return $this->belongsTo(User::class, 'pelanggan_id');
    }

    public function wilayahAntar(): BelongsTo
    {
        return $this->belongsTo(WilayahAntar::class, 'kurir_id');
    }

    public function kurir(): BelongsTo
    {
        return $this->belongsTo(WilayahAntar::class, 'kurir_id');
    }

    public function metodePembayaran(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }

    public function paymentMethod(): BelongsTo
    {
        return $this->belongsTo(PaymentMethod::class, 'payment_method_id');
    }

    public function detailPesanan(): HasMany
    {
        return $this->hasMany(DetailPesanan::class, 'order_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(DetailPesanan::class, 'order_id');
    }

    public function getAlamatAttribute(): ?string
    {
        return $this->attributes['alamat_penerima'] ?? null;
    }

    public function getTotalAttribute(): int
    {
        return (int) ($this->attributes['total_harga'] ?? 0);
    }

    public function canTransitionTo(string $status): bool
    {
        $transitions = [
            self::STATUS_MENUNGGU_PEMBAYARAN => [self::STATUS_MENUNGGU_KONFIRMASI, self::STATUS_DIBATALKAN],
            self::STATUS_MENUNGGU_KONFIRMASI => [self::STATUS_DIBAYAR, self::STATUS_DIBATALKAN],
            self::STATUS_DIBAYAR => [self::STATUS_DIPROSES],
            self::STATUS_DIPROSES => [self::STATUS_DIKIRIM],
            self::STATUS_DIKIRIM => [self::STATUS_SELESAI],
            self::STATUS_SELESAI => [],
            self::STATUS_DIBATALKAN => [],
        ];

        return in_array($status, $transitions[$this->status] ?? [], true);
    }
}
