import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/formatters.dart';
import '../core/utils/ui.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/inline_banner.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/state_views.dart';
import 'checkout_page.dart';
import 'product_detail_page.dart';

/// Keranjang. Isi dan subtotal selalu dari server; Flutter tidak menghitung total.
class CartPage extends StatefulWidget {
  const CartPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().loadIfStale();
    });
  }

  Future<void> _checkout() async {
    if (_navigating) return;
    _navigating = true;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const CheckoutPage()),
    );
    _navigating = false;
  }

  Future<void> _change(CartProvider cart, CartItem item, int quantity) async {
    final error = await cart.updateItem(item.id, quantity);
    if (error != null && mounted) showAppSnack(context, error, error: true);
  }

  Future<void> _remove(CartProvider cart, CartItem item) async {
    final error = await cart.removeItem(item.id);
    if (!mounted) return;
    if (error != null) showAppSnack(context, error, error: true);
  }

  Future<void> _clear(CartProvider cart) async {
    final ok = await confirmDialog(
      context,
      title: 'Kosongkan keranjang?',
      message: 'Semua produk di keranjang akan dihapus.',
      confirmLabel: 'Kosongkan',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final error = await cart.clearCart();
    if (error != null && mounted) showAppSnack(context, error, error: true);
  }

  void _openProduct(CartItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(productId: item.produkId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    Widget body;
    if (!cart.hasLoaded && cart.isLoading) {
      body = const LoadingView();
    } else if (!cart.hasLoaded && cart.errorMessage != null) {
      body = RefreshIndicator(
        onRefresh: cart.loadCart,
        child: ErrorView(message: cart.errorMessage!, onRetry: cart.loadCart),
      );
    } else if (cart.isEmpty) {
      body = RefreshIndicator(
        onRefresh: cart.loadCart,
        child: EmptyView(
          icon: Icons.shopping_basket_outlined,
          title: 'Keranjang masih kosong',
          message: 'Yuk, pilih produk segar favoritmu dulu.',
          actionLabel: 'Mulai Belanja',
          onAction: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<NavigationProvider>().select(AppTab.products);
          },
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: cart.loadCart,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          itemCount: cart.items.length + (cart.errorMessage != null ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (cart.errorMessage != null) {
              if (index == 0) {
                return InlineBanner(
                  message: cart.errorMessage!,
                  icon: Icons.info_outline_rounded,
                  actionLabel: 'Muat ulang',
                  onAction: cart.loadCart,
                );
              }
              index -= 1;
            }
            final item = cart.items[index];
            return _CartTile(
              key: ValueKey<int>(item.id),
              item: item,
              busy: cart.isItemBusy(item.id),
              onOpen: () => _openProduct(item),
              onQuantity: (q) => _change(cart, item, q),
              onRemove: () => _remove(cart, item),
            );
          },
        ),
      );
    }

    final showSummary = cart.hasLoaded && !cart.isEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        titleSpacing: widget.showBackButton ? 0 : 16,
        title: Text(
          cart.isEmpty ? 'Keranjang' : 'Keranjang (${cart.items.length})',
        ),
        actions: [
          if (showSummary)
            TextButton(
              onPressed: cart.isMutating ? null : () => _clear(cart),
              child: const Text('Kosongkan'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: body),
          if (showSummary)
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text('Subtotal', style: text.bodyMedium),
                          const Spacer(),
                          Text(
                            formatRupiah(cart.subtotal),
                            style: text.titleMedium?.copyWith(
                              color: p.brandText,
                            ),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Ongkos kirim dihitung saat checkout',
                          style: text.bodySmall?.copyWith(
                            color: p.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      PrimaryButton(
                        label: 'Checkout',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: cart.isMutating || cart.isLoading
                            ? null
                            : _checkout,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    super.key,
    required this.item,
    required this.busy,
    required this.onOpen,
    required this.onQuantity,
    required this.onRemove,
  });

  final CartItem item;
  final bool busy;
  final VoidCallback onOpen;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final maxed = item.jumlah >= item.stok;

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 84,
              height: 84,
              child: ProductImage(
                url: item.foto,
                cacheWidth: 240,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall,
                      ),
                    ),
                    InkResponse(
                      onTap: busy ? null : onRemove,
                      radius: 18,
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: busy
                              ? p.textSecondary.withValues(alpha: 0.4)
                              : p.danger,
                          semanticLabel: 'Hapus ${item.nama}',
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${formatRupiah(item.harga)}/${item.satuanJual}',
                  style: text.bodySmall?.copyWith(color: p.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    QuantitySelector(
                      compact: true,
                      value: item.jumlah,
                      max: item.stok > 0 ? item.stok : null,
                      busy: busy,
                      onChanged: onQuantity,
                    ),
                    const SizedBox(width: 8),
                    if (maxed)
                      Flexible(
                        child: Text(
                          'Stok maksimal',
                          style: text.labelSmall?.copyWith(color: p.warning),
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
}
