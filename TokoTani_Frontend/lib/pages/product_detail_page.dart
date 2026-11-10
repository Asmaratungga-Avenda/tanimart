import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
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
  bool isFavorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<ProductProvider>().loadProducts();
      });
    }
  }

  String _rupiah(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  Future<void> _addToCart(Product p) async {
    if (!p.tersedia || p.stok <= 0 || isAdding) return;

    setState(() => isAdding = true);
    try {
      final success = await context.read<CartProvider>().addItem(p.id, quantity);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${p.nama} ditambahkan ke keranjang'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'LIHAT',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
              ),
            ),
          ),
        );
      } else {
        final error = context.read<CartProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Gagal menambahkan ke keranjang.')),
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        Product? product;
        if (widget.initialProduct != null) {
          product = widget.initialProduct;
        } else {
          product = provider.products.where((p) => p.id == widget.productId).firstOrNull;
        }

        if (product == null && provider.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (product == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Produk tidak ditemukan')),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Header Image
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.red : colors.onSurface,
                        ),
                        onPressed: () => setState(() => isFavorite = !isFavorite),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: ProductImage(
                    imageUrl: product.foto,
                    productName: product.nama,
                    category: product.kategori,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              product.nama,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              product.stok > 0 ? 'Stok Tersedia' : 'Stok Habis',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'Rp ${_rupiah(product.harga)}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' / ${product.satuanJual}',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.orange[400], size: 20),
                          const SizedBox(width: 4),
                          const Text(
                            '4.8',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(2.5k ulasan)',
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Deskripsi Produk',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product.deskripsi ?? 'Tidak ada deskripsi produk.',
                        style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: colors.outlineVariant),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: quantity < product.stok ? () => setState(() => quantity++) : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            product.satuanJual,
                            style: TextStyle(color: colors.onSurfaceVariant, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            decoration: BoxDecoration(
              color: colors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: product.stok > 0 ? () => _addToCart(product!) : null,
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Tambah ke Keranjang'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: product.stok > 0 ? () {} : null,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Beli Sekarang'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange[800],
                      side: BorderSide(color: Colors.orange[800]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
