<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Delivery Simulation
    |--------------------------------------------------------------------------
    |
    | Untuk pengembangan dan demo, pesanan yang berstatus "dikirim" akan
    | secara otomatis berubah menjadi "tiba" setelah durasi yang dikonfigurasi.
    | Dalam produksi, fitur ini harus dinonaktifkan dan pengiriman diatur
    | secara nyata oleh admin / kurir.
    */

    'enabled' => env('DELIVERY_SIMULATION_ENABLED', true),

    'seconds' => (int) env('DELIVERY_SIMULATION_SECONDS', 5),

];
