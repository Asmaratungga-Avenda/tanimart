import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'pages/cart_page.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/order_history_page.dart';
import 'pages/profile_page.dart';
import 'pages/product_catalog_page.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';


void main() {
  runApp(const TaniMartApp());
}

class TaniMartApp extends StatelessWidget {
  final Widget? home;

  const TaniMartApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: _TaniMartMaterialApp(home: home),
    );
  }
}

typedef AgriMartApp = TaniMartApp;

class TokoTaniApp extends StatelessWidget {
  final Widget? home;

  const TokoTaniApp({super.key, this.home});

  @override
  Widget build(BuildContext context) {
    return TaniMartApp(home: home);
  }
}

class _TaniMartMaterialApp extends StatelessWidget {
  final Widget? home;

  const _TaniMartMaterialApp({this.home});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        if (themeProvider.isLoading) {
          return const Directionality(
            textDirection: TextDirection.ltr,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final isDark = themeProvider.isDark;
        final themeData = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;

        return MaterialApp(
          title: 'Tani Mart',
          debugShowCheckedModeBanner: false,
          theme: themeData,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.mode,
          home: home ?? const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (auth.sessionError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 44,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sesi belum dapat diperiksa',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(auth.sessionError!, textAlign: TextAlign.center),
                      const SizedBox(height: 18),
                      FilledButton(
                        onPressed: auth.retrySession,
                        child: const Text('Coba lagi'),
                      ),
                      TextButton(
                        onPressed: auth.signOut,
                        child: const Text('Keluar dari sesi ini'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return auth.isAuthenticated
            ? const MainNavigationPage()
            : const LoginPage();
      },
    );
  }
}

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk (CRUD)'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              leading: Icon(Icons.add_circle_outline),
              title: Text('Tambah Produk'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Halaman navigasi utama dengan Bottom Navigation Bar (5 tab).
/// Setiap tab mempertahankan state halaman melalui IndexedStack.
class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(onGoToCart: () => setState(() => _currentIndex = 2), onGoToProducts: () => setState(() => _currentIndex = 1)),
      const ProductCatalogPage(),
      const CartPage(),
      OrderHistoryPage(onGoToCatalog: () => setState(() => _currentIndex = 1)),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    const labels = ['Beranda', 'Produk', 'Keranjang', 'Pesanan', 'Akun'];
    const icons = [Icons.home_rounded, Icons.grid_view_rounded, Icons.shopping_bag_rounded, Icons.receipt_long_rounded, Icons.person_rounded];
    const outlines = [Icons.home_outlined, Icons.grid_view_outlined, Icons.shopping_bag_outlined, Icons.receipt_long_outlined, Icons.person_outline_rounded];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tani Mart'),
        centerTitle: true,
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: List.generate(5, (index) {
          final selected = _currentIndex == index;
          return NavigationDestination(
            icon: Icon(selected ? icons[index] : outlines[index]),
            label: labels[index],
          );
        }),
      ),
    );
  }
}
