import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'product_detail_page.dart';

/// Beranda baru TaniMart: editorial fresh-market, ringkas, dan berbasis data API.
class HomePage extends StatefulWidget {
  final VoidCallback? onGoToCart;
  final VoidCallback? onGoToProducts;
  const HomePage({super.key, this.onGoToCart, this.onGoToProducts});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ProductProvider>();
        provider.loadProducts();
        provider.loadBanners();
        provider.loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Product product) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ProductDetailPage(productId: product.id, initialProduct: product),
    ),
  );

  Future<void> _add(Product product) async {
    if (!product.tersedia || product.stok < 1) {
      _message('Produk sedang tidak tersedia.');
      return;
    }
    final ok = await context.read<CartProvider>().addItem(product.id, 1);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.nama} ditambahkan ke keranjang'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'LIHAT',
            onPressed: widget.onGoToCart ?? () {},
          ),
        ),
      );
    } else {
      _message(context.read<CartProvider>().errorMessage ?? 'Produk gagal ditambahkan.');
    }
  }

  void _message(String value) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(value), behavior: SnackBarBehavior.floating));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final productProvider = context.watch<ProductProvider>();
    final products = productProvider.products;
    final popularProducts = products.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: productProvider.refresh,
          child: CustomScrollView(
            slivers: [
              // Header & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo/agrimart_logo.png',
                            height: 32,
                            errorBuilder: (_, __, ___) => Row(
                              children: [
                                Icon(Icons.eco, color: colors.primary, size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'TaniMart',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_none_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: colors.surface,
                              side: BorderSide(color: colors.outlineVariant),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Halo, Pelanggan 👋',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Belanja Segar\nuntuk Keluarga',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _search,
                        onSubmitted: (_) => widget.onGoToProducts?.call(),
                        decoration: InputDecoration(
                          hintText: 'Cari produk di TaniMart...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: colors.outlineVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: productProvider.banners.isEmpty
                      ? Container(
                          height: 160,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: const DecorationImage(
                              image: AssetImage('assets/images/banners/banner_promo.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.6),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Diskon Spesial\nProduk Pertanian\nhingga 50%',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: widget.onGoToProducts,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: const Text('Belanja Sekarang →', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        )
                      : SizedBox(
                          height: 160,
                          child: PageView.builder(
                            itemCount: productProvider.banners.length,
                            itemBuilder: (context, index) {
                              final banner = productProvider.banners[index];
                              return Container(
                                margin: const EdgeInsets.only(right: 0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: ProductImage(
                                          imageUrl: banner.url,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Colors.black.withValues(alpha: 0.6),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              banner.judul,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (banner.link != null) ...[
                                              const SizedBox(height: 12),
                                              ElevatedButton(
                                                onPressed: widget.onGoToProducts,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: colors.primary,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                  minimumSize: Size.zero,
                                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                ),
                                                child: const Text('Lihat Detail →', style: TextStyle(fontSize: 12)),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),

              // Categories
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: productProvider.categories.isEmpty
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _categoryItem(context, 'Sayur', null),
                            _categoryItem(context, 'Buah', null),
                            _categoryItem(context, 'Pangan', null),
                            _categoryItem(context, 'Lainnya', null),
                          ],
                        )
                      : SizedBox(
                          height: 90,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: productProvider.categories.length,
                            itemBuilder: (context, index) {
                              final category = productProvider.categories[index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: _categoryItem(context, category.nama, category.gambarUrl),
                              );
                            },
                          ),
                        ),
                ),
              ),

              // Popular Products Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Produk Terlaris',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: widget.onGoToProducts,
                        child: const Text('Lihat Semua >'),
                      ),
                    ],
                  ),
                ),
              ),

              // Popular Products List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: productProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: popularProducts.length,
                          itemBuilder: (context, index) {
                            final product = popularProducts[index];
                            return _PopularProductCard(
                              product: product,
                              onTap: () => _open(product),
                              onAdd: () => _add(product),
                            );
                          },
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryItem(BuildContext context, String label, String? imageUrl) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        context.read<ProductProvider>().loadProducts(kategori: label);
        widget.onGoToProducts?.call();
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ProductImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    width: 40,
                    height: 40,
                  )
                : Icon(Icons.category, color: colors.primary),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PopularProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _PopularProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: ProductImage(
                  imageUrl: product.foto,
                  productName: product.nama,
                  category: product.kategori,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Rp ${_rupiah(product.harga)}',
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _rupiah(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}
