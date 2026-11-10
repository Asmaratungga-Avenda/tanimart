import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/cart_actions.dart';
import '../core/utils/formatters.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/inline_banner.dart';
import '../widgets/product_image.dart';
import '../widgets/quantity_selector.dart';
import '../widgets/state_views.dart';
import 'checkout_page.dart';

/// Detail produk. Data awal dipakai langsung, lalu disegarkan dari API agar stok akurat.
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  final int productId;
  final Product? initialProduct;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  Product? _product;
  String? _error;
  String? _refreshWarning;
  bool _loading = false;
  bool _buying = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _fetch();
  }

  Future<void> _fetch() async {
    final hadData = _product != null;
    setState(() {
      _loading = !hadData;
      _error = null;
      _refreshWarning = null;
    });
    try {
      final fresh = await ApiService.getProduct(widget.productId);
      if (!mounted) return;
      context.read<ProductProvider>().applyFresh(fresh);
      setState(() {
        _product = fresh;
        _quantity = fresh.stok > 0 ? _quantity.clamp(1, fresh.stok) : 1;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (hadData) {
          _refreshWarning = 'Stok terbaru belum dapat dimuat: ${e.message}';
        } else {
          _error = e.message;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        const message = 'Produk belum dapat dimuat. Silakan coba lagi.';
        if (hadData) {
          _refreshWarning = message;
        } else {
          _error = message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openCart() {
    context.read<NavigationProvider>().select(AppTab.cart);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _buyNow(Product product) async {
    if (_buying) return;
    setState(() => _buying = true);
    final navigator = Navigator.of(context);
    final ok = await addProductToCart(
      context,
      product,
      quantity: _quantity,
      announce: false,
    );
    if (!mounted) return;
    setState(() => _buying = false);
    if (ok) {
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => const CheckoutPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final cart = context.watch<CartProvider>();

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Produk')),
        body: _loading
            ? const LoadingView()
            : ErrorView(
                message: _error ?? 'Produk tidak ditemukan.',
                onRetry: _fetch,
              ),
      );
    }

    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final available = product.isAvailable;
    final adding = cart.isAdding(product.id);
    final total = product.harga * _quantity;

    return Scaffold(
      extendBodyBehindAppBar: false,
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              edgeOffset: 80,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.05,
                          child: ProductImage(
                            url: product.foto,
                            cacheWidth: 900,
                            iconSize: 64,
                          ),
                        ),
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                _RoundIconButton(
                                  icon: Icons.arrow_back_rounded,
                                  tooltip: 'Kembali',
                                  onTap: () => Navigator.of(context).maybePop(),
                                ),
                                const Spacer(),
                                _RoundIconButton(
                                  icon: Icons.shopping_bag_outlined,
                                  tooltip: 'Buka keranjang',
                                  badge: cart.badgeCount,
                                  onTap: _openCart,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: p.background,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_refreshWarning != null) ...[
                              InlineBanner(
                                message: _refreshWarning!,
                                icon: Icons.info_outline_rounded,
                                actionLabel: 'Muat ulang',
                                onAction: _fetch,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Text(product.nama, style: text.titleLarge),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  formatRupiah(product.harga),
                                  style: text.headlineSmall?.copyWith(
                                    color: p.brandText,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 3,
                                  ),
                                  child: Text(
                                    '/${product.satuanJual}',
                                    style: text.bodyMedium?.copyWith(
                                      color: p.textSecondary,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _StockPill(product: product),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppCard(
                              child: Column(
                                children: [
                                  _SpecRow('Kategori', product.kategori),
                                  _SpecRow('Satuan', product.satuanJual),
                                  _SpecRow(
                                    'Stok',
                                    '${product.stok} ${product.satuanJual}',
                                  ),
                                  _SpecRow(
                                    'Mudah rusak',
                                    product.mudahRusak ? 'Ya' : 'Tidak',
                                    last: true,
                                  ),
                                ],
                              ),
                            ),
                            if ((product.deskripsi ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 18),
                              Text('Deskripsi Produk', style: text.titleMedium),
                              const SizedBox(height: 6),
                              Text(
                                product.deskripsi!.trim(),
                                style: text.bodyMedium?.copyWith(
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    QuantitySelector(
                      value: _quantity,
                      max: available ? product.stok : 1,
                      onChanged: available
                          ? (v) => setState(() => _quantity = v)
                          : (_) {},
                    ),
                    const SizedBox(width: 10),
                    Text(
                      product.satuanJual,
                      style: text.bodyMedium?.copyWith(color: p.textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      formatRupiah(total),
                      style: text.titleMedium?.copyWith(color: p.brandText),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: available ? 'Tambah ke Keranjang' : 'Stok Habis',
                  icon: available ? Icons.add_shopping_cart_rounded : null,
                  loading: adding,
                  onPressed: available && !_buying
                      ? () => addProductToCart(
                          context,
                          product,
                          quantity: _quantity,
                        )
                      : null,
                ),
                if (available) ...[
                  const SizedBox(height: 8),
                  SecondaryButton(
                    label: 'Beli Sekarang',
                    icon: Icons.bolt_rounded,
                    onPressed: adding || _buying ? null : () => _buyNow(product),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: p.surface.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            elevation: 1,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 42,
                height: 42,
                child: Icon(icon, color: p.textPrimary, size: 22),
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: scheme.error,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: TextStyle(
                    color: scheme.onError,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  const _StockPill({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final available = product.isAvailable;
    final low = available && product.stok <= 5;
    final (bg, fg, label) = !available
        ? (p.neutralSoft, p.neutral, 'Stok Habis')
        : low
        ? (p.warningSoft, p.warning, 'Stok Terbatas')
        : (p.successSoft, p.success, 'Stok Tersedia');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow(this.label, this.value, {this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: p.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: text.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
