# TokoTani

Aplikasi e-commerce produk pertanian dan kebutuhan harian — **TokoTani**.

Repository ini berisi dua aplikasi yang dikelola terpisah:

- `TokoTani_Backend/` — REST API berbasis Laravel 13 + Filament v5 Admin Panel.
- `TokoTani_Frontend/` — Aplikasi mobile Flutter (Android & Desktop).

## Frontend

Jalankan perintah berikut dari folder frontend:

```shell
cd TokoTani_Frontend
flutter pub get
flutter test
flutter run
```

## Backend

```shell
cd TokoTani_Backend
php artisan serve --host=0.0.0.0 --port=8000
```

Panel admin tersedia di: `http://localhost:8000/admin`

Ikuti petunjuk lengkap di [`docs/integration-guide.md`](docs/integration-guide.md).
