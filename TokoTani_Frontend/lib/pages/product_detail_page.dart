import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/notification_service.dart';
import '../core/theme/theme_extension.dart';
import '../widgets/responsive_wrapper.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Product? initialProduct;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int quantity = 1;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ProductProvider>().loadProducts();
      });
    }
  }

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (match) => '${match[1]}.')}';
  }

  Future<void> addToCart(Product p) async {
    if (!p.tersedia || p.stok <= 0 || isAdding) return;

    final theme = AppColors.of(context);
    setState(() => isAdding = true);

    try {
      final success = await context.read<CartProvider>().addItem(p.id, quantity);
      if (!mounted) return;
      if (success) {
        NotificationService.cartCountNotifier.value++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle_outline, color: theme.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Berhasil menambahkan $quantity ${p.satuanJual} ke keranjang!'),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
        );
      } else {
        final error = context.read<CartProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.errorRed,
            behavior: SnackBarBehavior.floating,
            content: Text(error ?? 'Gagal menambahkan ke keranjang.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.errorRed,
            behavior: SnackBarBehavior.floating,
            content: Text('Terjadi kesalahan sambungan jaringan.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        Product? product;
        bool isLoading = provider.isLoading;
        String? errorMessage = provider.errorMessage;
        final theme = AppColors.of(context);

        if (widget.initialProduct != null) {
          product = widget.initialProduct;
        } else {
          product = provider.products.where((p) => p.id == widget.productId).firstOrNull;
        }

        if (widget.initialProduct == null && provider.isEmpty && !provider.isLoading && errorMessage == null) {
          isLoading = true;
        }

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            title: Text(product?.nama ?? 'Rincian Produk'),
            actions: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Keranjang',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
                  );
                },
              ),
            ],
          ),
          body: ResponsiveScrollWrapper(
            child: _buildBody(provider, product, isLoading, errorMessage),
          ),
          bottomNavigationBar: product != null && !isLoading
              ? _buildBottomBar(product)
              : null,
        );
      },
    );
  }

  Widget _buildBody(ProductProvider provider, Product? p, bool isLoading, String? errorMessage) {
    final theme = AppColors.of(context);
    if (isLoading && p == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat rincian produk...'),
          ],
        ),
      );
    }

    if (p == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: theme.textSecondary),
              const SizedBox(height: 16),
              const Text('Produk Tidak Ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(errorMessage ?? 'Produk ini mungkin telah dihapus atau tidak lagi tersedia.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.primaryGreen),
                onPressed: () => provider.loadProducts(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final isOutOfStock = p.stok <= 0 || !p.tersedia;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        Container(
          height: 220,
          decoration: BoxDecoration(
            color: isOutOfStock ? theme.mutedContainer : theme.lightGreen,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.borderColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ProductImage(
              imageUrl: p.foto,
              productName: p.nama,
              category: p.kategori,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                p.kategori,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryGreen,
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (p.mudahRusak)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.warningContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.warning.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt_rounded, size: 14, color: theme.warning),
                    const SizedBox(width: 4),
                    Text(
                      'Mudah Rusak (Wajib Same Day)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.warning,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          p.nama,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              formatRupiah(p.harga),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme.primaryGreen,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '/ ${p.satuanJual}',
              style: TextStyle(fontSize: 14, color: theme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isOutOfStock ? Icons.cancel_outlined : Icons.check_circle_outline,
                    color: isOutOfStock ? theme.errorRed : theme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOutOfStock ? 'Tidak Tersedia / Stok Habis' : 'Stok Tersedia',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isOutOfStock ? theme.errorRed : theme.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '${p.stok} ${p.satuanJual}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Deskripsi Produk',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.deskripsi != null && p.deskripsi!.trim().isNotEmpty
              ? p.deskripsi!
              : 'Deskripsi produk belum tersedia.',
              style: TextStyle(fontSize: 14, color: theme.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 20),

        if (p.mudahRusak)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.warningContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.warning.withValues(alpha: 0.4)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: theme.warning, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aturan Pengiriman Produk Segar',
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.warning),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Produk ini mudah layu/rusak. Pada saat checkout, sistem server mewajibkan pengiriman pada hari yang sama (Same Day) untuk menjaga kesegaran.',
                        style: TextStyle(fontSize: 12, color: theme.warning, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBottomBar(Product p) {
    final theme = AppColors.of(context);
    final isOutOfStock = p.stok <= 0 || !p.tersedia;

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            offset: const Offset(0, -3),
            blurRadius: 12,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  if (!isOutOfStock) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: theme.mutedContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: quantity < p.stok ? () => setState(() => quantity++) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primaryGreen,
                          disabledBackgroundColor: theme.mutedContainer,
                          disabledForegroundColor: theme.textSecondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: isAdding
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: theme.onPrimary),
                              )
                            : Icon(isOutOfStock ? Icons.block : Icons.add_shopping_cart_rounded),
                        label: Text(
                          isOutOfStock ? 'Stok Tidak Tersedia' : 'Tambah ke Keranjang',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        onPressed: isOutOfStock || isAdding ? null : () => addToCart(p),
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
