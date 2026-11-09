import 'package:flutter/material.dart';
import 'pages/cart_page.dart';
import 'pages/catalog_page.dart';
import 'pages/checkout_page.dart';
import 'pages/manage_product_page.dart';
import 'pages/order_history_page.dart';
import 'pages/product_form_page.dart';
import 'services/api_service.dart';
import 'widgets/responsive_wrapper.dart';

void main() {
  runApp(const TokoTaniApp());
}

class TokoTaniApp extends StatelessWidget {
  final Widget? home;

  const TokoTaniApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriMart - TokoTani',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
          surface: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1E293B),
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
      // Langsung membuka navigasi utama terfokus: Keranjang Belanja & Kelola Produk
      home: home ?? const MainFocusedPage(),
    );
  }
}

/// Halaman Navigasi Utama yang berfokus tepat pada 2 tugas Anggota 5:
/// 1. Keranjang Belanja (Subtotal server & Galat 409)
/// 2. Kelola Produk (CRUD Lengkap dari dalam aplikasi)
class MainFocusedPage extends StatefulWidget {
  final int initialIndex;

  const MainFocusedPage({super.key, this.initialIndex = 0});

  @override
  State<MainFocusedPage> createState() => _MainFocusedPageState();
}

class _MainFocusedPageState extends State<MainFocusedPage> {
  late int _currentIndex;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pages = [
      const CatalogPage(),
      CartPage(onGoToCatalog: () => setState(() => _currentIndex = 0)),
      OrderHistoryPage(onGoToCatalog: () => setState(() => _currentIndex = 0)),
      const ManageProductsPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'TokoTani',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 19,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Tombol Beralih Mode Jalur A (Laravel API) vs Jalur B (Data Tiruan Offline)
          // Tampil adaptif: mode ringkas di layar sempit/mobile, mode badge penuh di desktop
          Builder(
            builder: (ctx) {
              final isNarrow = MediaQuery.sizeOf(ctx).width < 500;
              void toggleMode() {
                setState(() {
                  ApiService.useMock = !ApiService.useMock;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: ApiService.useMock ? Colors.orange.shade900 : const Color(0xFF2E7D32),
                    behavior: SnackBarBehavior.floating,
                    content: Text(
                      ApiService.useMock
                          ? 'Beralih ke Jalur B (Data Tiruan Offline)'
                          : 'Beralih ke Jalur A (Server Laravel ${ApiService.baseUrl})',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }

              if (isNarrow) {
                return IconButton(
                  icon: Icon(
                    ApiService.useMock ? Icons.science_outlined : Icons.cloud_done_outlined,
                    color: Colors.white,
                  ),
                  tooltip: ApiService.useMock ? 'Mode Mock Offline' : 'Mode Laravel API',
                  onPressed: toggleMode,
                );
              }

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: toggleMode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ApiService.useMock ? Icons.science_outlined : Icons.cloud_done_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ApiService.useMock ? 'Mock Offline' : 'Laravel API',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Tombol Buka Menu Evaluasi Rubrik
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.white),
            tooltip: 'Ringkasan Tugas & Rubrik',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MenuPage()),
              );
            },
          ),
        ],
      ),
      body: ResponsiveScrollWrapper(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            heightFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) => setState(() => _currentIndex = index),
                backgroundColor: Colors.white,
                elevation: 0,
                indicatorColor: const Color(0xFFE8F5E9),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront, color: Color(0xFF2E7D32)),
                    label: 'Katalog',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart_outlined),
                    selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFF2E7D32)),
                    label: 'Keranjang Belanja',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long, color: Color(0xFF2E7D32)),
                    label: 'Riwayat Pesanan',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.inventory_2_outlined),
                    selectedIcon: Icon(Icons.inventory_2, color: Color(0xFF2E7D32)),
                    label: 'Kelola Produk',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Halaman evaluasi dan navigasi cepat pengujian tugas Anggota 5 (Frontend)
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'TokoTani',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ResponsiveScrollWrapper(
        child: ListView(
          padding: const EdgeInsets.all(16),
        children: [
          // Banner Identitas Bagian 5
          Card(
            color: Colors.green.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.assignment_ind, color: Colors.green.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Bagian Anggota 5: Frontend',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tugas: Halaman Keranjang Belanja (Subtotal server & Galat 409) '
                    'serta Halaman Kelola Produk (CRUD Produk Pertanian Lengkap).',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  // Toggle Mode API Real (Jalur A) vs Mock (Jalur B)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              ApiService.useMock ? Icons.science_outlined : Icons.cloud_done_outlined,
                              size: 18,
                              color: ApiService.useMock ? Colors.orange.shade800 : Colors.green.shade800,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ApiService.useMock ? 'Mode: Data Tiruan (Jalur B)' : 'Mode: REST API Laravel (Jalur A)',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Switch(
                          value: ApiService.useMock,
                          activeThumbColor: const Color(0xFF2E7D32),
                          onChanged: (val) {
                            setState(() {
                              ApiService.useMock = val;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Beralih ke Jalur B (Data Tiruan Offline)'
                                      : 'Beralih ke Jalur A (Server Laravel ${ApiService.baseUrl})',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Menu Navigasi Tugas (7 Halaman Wajib)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          // Menu 1: Keranjang Belanja
          _MenuCard(
            icon: Icons.shopping_cart_outlined,
            title: 'Keranjang Belanja',
            subtitle: 'Membaca subtotal server, ubah kuantitas, hapus item, dan notifikasi galat 409.',
            badgeText: 'Subtotal Server',
            badgeColor: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
            ),
          ),
          const SizedBox(height: 12),

          // Menu 2: Kelola Produk
          _MenuCard(
            icon: Icons.inventory_2_outlined,
            title: 'Kelola Produk (CRUD)',
            subtitle: 'Daftar produk dengan pencarian/kategori server, tombol ubah & hapus (galat 409).',
            badgeText: 'CRUD Lengkap',
            badgeColor: Colors.green,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManageProductsPage()),
            ),
          ),
          const SizedBox(height: 12),

          // Menu 3: Katalog Produk Pertanian
          _MenuCard(
            icon: Icons.storefront_outlined,
            title: 'Katalog Produk Pertanian',
            subtitle: 'Daftar produk dengan penyaring kategori, pencarian nama, penanda stok habis, & badge keranjang.',
            badgeText: 'GET /api/produk',
            badgeColor: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CatalogPage(showBackButton: true)),
            ),
          ),
          const SizedBox(height: 12),

          // Menu 4: Tambah Produk Baru
          _MenuCard(
            icon: Icons.add_box_outlined,
            title: 'Tambah Produk Baru',
            subtitle: 'Formulir produk dengan validasi per kolom 422 dan atribut domain pertanian.',
            badgeText: 'Validasi 422',
            badgeColor: Colors.orange,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProductFormPage()),
            ),
          ),
          const SizedBox(height: 12),

          // Menu 5: Halaman Checkout
          _MenuCard(
            icon: Icons.shopping_bag_outlined,
            title: 'Checkout Pesanan',
            subtitle: 'Tampilan checkout dengan model list barang, harga, jumlah, dan urutan barang sesuai jumlah.',
            badgeText: 'List & Urutan',
            badgeColor: Colors.teal,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutPage()),
            ),
          ),
          const SizedBox(height: 12),

          // Menu 6: Riwayat Pesanan
          _MenuCard(
            icon: Icons.receipt_long_outlined,
            title: 'Riwayat Pesanan',
            subtitle: 'Daftar pesanan terurut dari yang terbaru beserta status, menuju rincian pesanan.',
            badgeText: 'GET /api/pesanan',
            badgeColor: Colors.indigo,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryPage(showBackButton: true)),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badgeText;
  final MaterialColor badgeColor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.shade50,
                child: Icon(icon, color: Colors.green.shade800),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: badgeColor.shade200),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: badgeColor.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

typedef MainNavPage = MainFocusedPage;

