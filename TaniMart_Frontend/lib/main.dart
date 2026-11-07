import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/product_images.dart';
import 'pages/cart_page.dart';
import 'pages/home_page.dart';
import 'pages/manage_product_page.dart';
import 'pages/orders_page.dart';
import 'pages/product_catalog_page.dart';
import 'pages/product_form_page.dart';
import 'pages/profile_page.dart';
import 'pages/notifications_page.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'widgets/responsive_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  await NotificationService.init();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const TaniMartApp());
}

class TaniMartApp extends StatelessWidget {
  final Widget? home;

  const TaniMartApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tani Mart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home ?? const MainNavPage(),
    );
  }
}

/// Alias kompatibilitas untuk unit testing TaniMartApp
class TokoTaniApp extends StatelessWidget {
  final Widget? home;

  const TokoTaniApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return TaniMartApp(home: home);
  }
}

// ───────── 5-Tab Main Navigation ─────────

class MainNavPage extends StatefulWidget {
  final int initialIndex;

  const MainNavPage({super.key, this.initialIndex = 0});

  @override
  State<MainNavPage> createState() => _MainNavPageState();
}

class _MainNavPageState extends State<MainNavPage> {
  late int _currentIndex;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _refreshCartCount();
  }

  void _refreshCartCount() async {
    try {
      final cart = await ApiService.getCart();
      if (!mounted) return;
      final count = cart.items.fold(0, (sum, i) => sum + i.jumlah);
      NotificationService.cartCountNotifier.value = count;
    } catch (_) {}
  }

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
    _refreshCartCount();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        onGoToCart: () => _goToTab(2),
        onGoToProducts: () => _goToTab(1),
      ),
      const ProductCatalogPage(),
      CartPage(
        showBackButton: false,
        onCheckout: () => _goToTab(3),
      ),
      const OrdersPage(),
      const ManageProductsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                ProductImages.logo,
                height: 28,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, color: Colors.white, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Tani Mart',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          // Lonceng Notifikasi Reaktif (Langsung bertambah saat checkout)
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.unreadCountNotifier,
            builder: (context, unreadCount, _) {
              return IconButton(
                icon: Badge(
                  isLabelVisible: unreadCount > 0,
                  label: Text('$unreadCount'),
                  backgroundColor: const Color(0xFFDC2626),
                  child: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                ),
                tooltip: 'Notifikasi',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationsPage()),
                  );
                },
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            tooltip: 'Profil Saya',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              );
            },
          ),
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
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _goToTab,
          backgroundColor: Colors.white,
          elevation: 0,
          indicatorColor: _lightGreen,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: _primaryGreen),
              label: 'Beranda',
            ),
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront, color: _primaryGreen),
              label: 'Produk',
            ),
            // Badge Keranjang Reaktif (ValueListenable)
            NavigationDestination(
              icon: ValueListenableBuilder<int>(
                valueListenable: NotificationService.cartCountNotifier,
                builder: (context, count, _) => Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: const Color(0xFFF59E0B),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
              ),
              selectedIcon: ValueListenableBuilder<int>(
                valueListenable: NotificationService.cartCountNotifier,
                builder: (context, count, _) => Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: const Color(0xFFF59E0B),
                  child: const Icon(Icons.shopping_cart, color: _primaryGreen),
                ),
              ),
              label: 'Keranjang Belanja',
            ),
            // Badge Pesanan Reaktif (ValueListenable)
            NavigationDestination(
              icon: ValueListenableBuilder<int>(
                valueListenable: NotificationService.newOrdersCountNotifier,
                builder: (context, count, _) => Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: _primaryGreen,
                  child: const Icon(Icons.receipt_long_outlined),
                ),
              ),
              selectedIcon: ValueListenableBuilder<int>(
                valueListenable: NotificationService.newOrdersCountNotifier,
                builder: (context, count, _) => Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  backgroundColor: _primaryGreen,
                  child: const Icon(Icons.receipt_long, color: _primaryGreen),
                ),
              ),
              label: 'Pesanan',
            ),
            const NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2, color: _primaryGreen),
              label: 'Kelola Produk',
            ),
          ],
        ),
      ),
    );
  }
}

/// Halaman evaluasi dan navigasi cepat pengujian tugas (Tani Mart)
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
              'Tani Mart',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: ResponsiveScrollWrapper(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                          'Sistem E-Commerce Tani Mart',
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
                      'Aplikasi e-commerce pertanian modern: Katalog Produk, Keranjang (Subtotal Server), Checkout & Ongkir, Riwayat Pesanan, dan Kelola Produk (CRUD).',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 10),
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
              'Menu Navigasi Tugas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
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
            _MenuCard(
              icon: Icons.inventory_2_outlined,
              title: 'Kelola Produk (CRUD)',
              subtitle: 'Daftar produk dengan pencarian/kategori server, tombol ubah & hapus.',
              badgeText: 'CRUD Lengkap',
              badgeColor: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageProductsPage()),
              ),
            ),
            const SizedBox(height: 12),
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
            _MenuCard(
              icon: Icons.storefront_outlined,
              title: 'Katalog Produk',
              subtitle: 'Jelajahi produk pertanian, filter kategori, dan pencarian.',
              badgeText: 'Katalog',
              badgeColor: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductCatalogPage()),
              ),
            ),
            const SizedBox(height: 12),
            _MenuCard(
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Pesanan',
              subtitle: 'Daftar transaksi pelanggan beserta status dan rincian pengiriman.',
              badgeText: 'Pesanan',
              badgeColor: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdersPage()),
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
