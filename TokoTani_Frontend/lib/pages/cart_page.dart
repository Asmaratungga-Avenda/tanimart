import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_extension.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/responsive_wrapper.dart';
import 'product_catalog_page.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onGoToCatalog;

  const CartPage({
    super.key,
    this.showBackButton = false,
    this.onGoToCatalog,
  });

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().loadCart();
    });
  }

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> changeQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;
    final cartProvider = context.read<CartProvider>();
    final success = await cartProvider.updateItem(item.id, newQuantity);
    if (!mounted) return;
    if (!success) {
      final error = cartProvider.errorMessage;
      _showErrorNotification(error ?? 'Gagal memperbarui jumlah barang.');
    }
  }

  Future<void> removeItem(CartItem item) async {
    final cartProvider = context.read<CartProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppColors.of(ctx).errorRed),
            const SizedBox(width: 8),
            const Text('Hapus Item'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menghapus "${item.nama}" dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(ctx).errorRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await cartProvider.removeItem(item.id);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.of(context).primaryGreen,
          content: Text('"${item.nama}" berhasil dihapus dari keranjang.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      final error = cartProvider.errorMessage;
      _showErrorNotification(error ?? 'Gagal menghapus item dari keranjang.');
    }
  }

  Future<void> clearAllItems() async {
    final cartProvider = context.read<CartProvider>();
    if (cartProvider.isLoading || cartProvider.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.delete_sweep_outlined, color: AppColors.of(ctx).errorRed),
            const SizedBox(width: 8),
            const Text('Kosongkan Keranjang'),
          ],
        ),
        content: const Text('Hapus semua produk dari keranjang belanja?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.of(ctx).errorRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await cartProvider.clearCart();
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.of(context).primaryGreen,
          content: Text('Keranjang berhasil dikosongkan.'),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _showErrorNotification(
        cartProvider.errorMessage ?? 'Gagal mengosongkan keranjang.',
      );
    }
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.of(context).errorRed,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.of(context).onPrimary),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.of(context);
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Keranjang Belanja',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textPrimary,
        elevation: 0.5,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: theme.errorRed),
              tooltip: 'Kosongkan Keranjang',
              onPressed: cart.isLoading ? null : clearAllItems,
            ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.primaryGreen),
            tooltip: 'Segarkan Keranjang',
            onPressed: cart.isLoading ? null : () => cart.loadCart(),
          ),
        ],
      ),
      body: ResponsiveScrollWrapper(child: _buildBody(cart, theme)),
      bottomNavigationBar: cart.isLoading ||
              cart.errorMessage != null ||
              cart.items.isEmpty
          ? null
          : _buildBottomBar(cart, theme),
    );
  }

  Widget _buildBody(CartProvider cart, AppColors theme) {
    if (cart.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryGreen),
      );
    }

    if (cart.errorMessage != null) {
      return _buildErrorState(cart.errorMessage!, theme);
    }

    if (cart.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: theme.primaryGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Keranjang Belanja Kosong',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Belum ada produk hasil tani segar di keranjang Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: theme.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Mulai Belanja Produk Segar'),
                onPressed: () {
                  if (widget.onGoToCatalog != null) {
                    widget.onGoToCatalog!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProductCatalogPage()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => cart.loadCart(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: cart.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = cart.items[index];
          return _buildCartCard(item, theme);
        },
      ),
    );
  }

  Widget _buildErrorState(String message, AppColors theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.errorRed),
            const SizedBox(height: 16),
            Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textSecondary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: theme.primaryGreen),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              onPressed: () => context.read<CartProvider>().loadCart(),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getItemIcon(CartItem item) {
    final lower = item.nama.toLowerCase();
    if (lower.contains('beras') || lower.contains('padi')) return Icons.grain_rounded;
    if (lower.contains('cabai') || lower.contains('bawang') || lower.contains('bumbu') || lower.contains('rempah')) {
      return Icons.local_fire_department_rounded;
    }
    if (lower.contains('sayur') || lower.contains('bayam') || lower.contains('kangkung')) return Icons.eco_rounded;
    if (lower.contains('buah') || lower.contains('pisang') || lower.contains('jeruk')) return Icons.apple_rounded;
    if (lower.contains('umbi') || lower.contains('kentang')) return Icons.spa_rounded;
    return item.mudahRusak ? Icons.local_florist_rounded : Icons.eco_rounded;
  }

  List<Color> _getItemGradient(AppColors theme) {
    return [theme.lightGreen, theme.mutedContainer];
  }

  Color _getItemAccent(CartItem item, AppColors theme) {
    return item.mudahRusak ? theme.warning : theme.primaryGreen;
  }

  Widget _buildCartCard(CartItem item, AppColors theme) {
    final itemTotal = item.harga * item.jumlah;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
        boxShadow: theme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getItemGradient(theme),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _getItemIcon(item),
              size: 36,
              color: _getItemAccent(item, theme),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.nama,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: theme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${formatRupiah(item.harga)} / ${item.satuanJual}',
                            style: TextStyle(
                              color: theme.primaryGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (item.mudahRusak)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.warningContainer,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.warning.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt, size: 10, color: theme.warning),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Wajib Instan/Same-Day',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: theme.warning,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => removeItem(item),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: theme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: theme.mutedContainer,
                        border: Border.all(color: theme.borderColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                              onTap: item.jumlah <= 1
                                  ? null
                                  : () => changeQuantity(item, item.jumlah - 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: item.jumlah > 1
                                      ? theme.textPrimary
                                      : theme.borderColor,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 28),
                            alignment: Alignment.center,
                            child: Text(
                              '${item.jumlah}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                              onTap: () => changeQuantity(item, item.jumlah + 1),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: theme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Text(
                      formatRupiah(itemTotal),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CartProvider cart, AppColors theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            offset: const Offset(0, -4),
            blurRadius: 14,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Belanja (${cart.items.length} item)',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Subtotal dari API server',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatRupiah(cart.subtotal),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.primaryGreen,
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: cart.isLoading
                          ? null
                          : () async {
                              if (cart.items.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Keranjang belanja masih kosong.'),
                                    backgroundColor: theme.warning,
                                  ),
                                );
                                return;
                              }
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const CheckoutPage(),
                                ),
                              );
                              if (result == true && mounted) {
                                cart.loadCart();
                              }
                            },
                      child: cart.isLoading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: theme.onPrimary,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Checkout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: theme.onPrimary,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                  color: theme.onPrimary,
                                ),
                              ],
                            ),
                    ),
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
