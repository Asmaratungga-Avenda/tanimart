import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/app_bottom_nav.dart';
import 'cart_page.dart';
import 'home_page.dart';
import 'order_history_page.dart';
import 'product_catalog_page.dart';
import 'profile_page.dart';

/// Kerangka aplikasi setelah login: lima tab, dibangun hanya saat pertama dibuka.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final Set<int> _visited = <int>{AppTab.home};
  late final NavigationProvider _nav;

  @override
  void initState() {
    super.initState();
    _nav = context.read<NavigationProvider>();
    _nav.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nav.reset();
      context.read<CartProvider>().loadIfStale();
    });
  }

  @override
  void dispose() {
    _nav.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    switch (_nav.index) {
      case AppTab.cart:
        context.read<CartProvider>().loadIfStale();
      case AppTab.orders:
        context.read<OrderProvider>().loadIfStale();
    }
  }

  Widget _page(int index) {
    if (!_visited.contains(index)) return const SizedBox.shrink();
    switch (index) {
      case AppTab.home:
        return const HomePage();
      case AppTab.products:
        return const ProductCatalogPage();
      case AppTab.cart:
        return const CartPage();
      case AppTab.orders:
        return const OrderHistoryPage();
      default:
        return const ProfilePage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final index = context.select<NavigationProvider, int>((n) => n.index);
    final cartCount = context.select<CartProvider, int>((c) => c.badgeCount);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    _visited.add(index);

    return PopScope(
      canPop: index == AppTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _nav.select(AppTab.home);
      },
      child: Scaffold(
        body: IndexedStack(
          index: index,
          children: [for (var i = 0; i < 5; i++) _page(i)],
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : AppBottomNav(
                currentIndex: index,
                cartCount: cartCount,
                onSelected: _nav.select,
              ),
      ),
    );
  }
}
