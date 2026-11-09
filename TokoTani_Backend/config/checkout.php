<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Batas Maksimum Produk Mudah Rusak
    |--------------------------------------------------------------------------
    |
    | Kuantitas maksimum per produk mudah rusak dalam satu pesanan. Nilai ini
    | disepakati sebagai aturan domain checkout dan dapat diubah lewat env.
    |
    */
    'max_mudah_rusak_per_pesanan' => (int) env('CHECKOUT_MAX_MUDAH_RUSAK', 5),

    /*
    |--------------------------------------------------------------------------
    | Slot Pengantaran
    |--------------------------------------------------------------------------
    */
    'slot_pengantaran' => ['pagi', 'siang', 'sore'],
];
