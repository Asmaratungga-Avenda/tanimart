import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/constants/product_images.dart';
import '../core/theme/theme_extension.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/notification_service.dart';
import 'product_detail_page.dart';
import 'product_catalog_page.dart';

/// Halaman Beranda Tani Mart
/// Konsep Desain: FRESH MARKET — MODERN AGRICULTURE
class HomePage extends StatefulWidget {
  final VoidCallback? onGoToCart;
  final VoidCallback? onGoToProducts;

  const HomePage({super.key, this.onGoToCart, this.onGoToProducts});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _banners = [
    {
      'image': ProductImages.bannerPromo,
      'title': 'Belanja Segar,\nHarga Bersahabat',
      'subtitle': 'Produk pertanian segar pilihan langsung dari petani mitra',
    },
    {
      'image': ProductImages.bannerPertanian,
      'title': 'Lengkapi Kebutuhan\nPertanianmu',
      'subtitle': 'Bibit unggul, pupuk organik, dan alat tani terlengkap',
    },
  ];



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = context.read<ProductProvider>();
        provider.loadCategories();
        provider.loadProducts();
      }
    });
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_bannerIndex + 1) % _banners.length;
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String? _findCategory(ProductProvider provider, List<String> keywords) {
    for (final category in provider.categories) {
      final normalized = category.toLowerCase();
      if (keywords.any(normalized.contains)) return category;
    }
    return null;
  }

  void _navigateToCatalog({String? category, String? query}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductCatalogPage(
          initialCategory: category,
          initialQuery: query,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.of(context);
    final provider = context.watch<ProductProvider>();
    final products = provider.products;

    final featuredProducts =
        products.where((p) => p.tersedia && p.stok > 0).take(6).toList();
    final bestSellingProducts = products.reversed.take(6).toList();
    final agriculturalProducts = products.where((p) {
      final k = p.kategori.toLowerCase();
      final n = p.nama.toLowerCase();
      return k.contains('sayur') ||
          k.contains('buah') ||
          k.contains('bibit') ||
          k.contains('pupuk') ||
          n.contains('bayam') ||
          n.contains('tomat') ||
          n.contains('cabai') ||
          n.contains('kangkung');
    }).toList();
    final dailyNecessities = products.where((p) {
      final k = p.kategori.toLowerCase();
      final n = p.nama.toLowerCase();
      return k.contains('sembako') ||
          k.contains('harian') ||
          n.contains('beras') ||
          n.contains('minyak') ||
          n.contains('telur') ||
          n.contains('gula') ||
          n.contains('terigu');
    }).toList();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: RefreshIndicator(
        color: theme.primaryGreen,
        onRefresh: () => provider.refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildGreetingHeader(theme)),
            SliverToBoxAdapter(child: _buildSearchBar(theme)),
            SliverToBoxAdapter(child: _buildBannerCarousel(theme)),
            SliverToBoxAdapter(child: _buildCategorySection(theme)),

            if (provider.isLoading)
              const SliverToBoxAdapter(child: _LoadingSkeleton())
            else if (provider.errorMessage != null)
              SliverToBoxAdapter(child: _buildError(provider.errorMessage!, theme))
            else ...[
              if (featuredProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Produk Rekomendasi',
                    Icons.star_rounded,
                    theme,
                    onSeeAll: widget.onGoToProducts,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(featuredProducts, theme),
                ),
              ],
              if (bestSellingProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Produk Terlaris',
                    Icons.local_fire_department_rounded,
                    theme,
                    onSeeAll: widget.onGoToProducts,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(bestSellingProducts, theme),
                ),
              ],
              if (agriculturalProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Produk Pertanian Segar',
                    Icons.eco_rounded,
                    theme,
                    onSeeAll: () => _navigateToCatalog(
                      category: _findCategory(provider, ['sayur', 'buah']),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(agriculturalProducts, theme),
                ),
              ],
              if (dailyNecessities.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Kebutuhan Harian & Sembako',
                    Icons.shopping_basket_rounded,
                    theme,
                    onSeeAll: () => _navigateToCatalog(
                      category: _findCategory(provider, ['sembako', 'harian']),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(dailyNecessities, theme),
                ),
              ],
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Katalog Lengkap',
                  Icons.grid_view_rounded,
                  theme,
                  onSeeAll: widget.onGoToProducts,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.62,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _ProductCard(
                      product: products[i],
                      theme: theme,
                      onTap: () => _openDetail(products[i]),
                      onAddToCart: () => _addToCart(products[i]),
                    ),
                    childCount: products.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader(AppColors theme) {
    final foreground = theme.isDark ? theme.textPrimary : theme.onPrimary;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.isDark
              ? [theme.backgroundColor, theme.surfaceColor]
              : [theme.primaryGreen, theme.scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang di Tani Mart 👋',
                      style: GoogleFonts.poppins(
                        color: foreground,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kebutuhan Pertanian dan Harian dalam Satu Genggaman',
                      style: GoogleFonts.poppins(
                        color: foreground.withValues(alpha: 0.88),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: widget.onGoToCart,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: foreground.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: foreground,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppColors theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
          boxShadow: theme.softShadow,
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _navigateToCatalog(query: query.trim());
            }
          },
          style: GoogleFonts.poppins(color: theme.textPrimary),
          decoration: InputDecoration(
            hintText: 'Cari produk pertanian atau kebutuhan harian...',
            hintStyle: GoogleFonts.poppins(
              color: theme.textSecondary,
              fontSize: 12.5,
            ),
            prefixIcon: Icon(Icons.search, color: theme.primaryGreen, size: 22),
            suffixIcon: IconButton(
              icon: Icon(Icons.tune_rounded, color: theme.primaryGreen, size: 20),
              tooltip: 'Buka Katalog & Filter',
              onPressed: () => _navigateToCatalog(
                query: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              ),
            ),
            filled: true,
            fillColor: theme.surfaceColor,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(AppColors theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Column(
        children: [
          SizedBox(
            height: 155,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (ctx, i) {
                final b = _banners[i];
                return GestureDetector(
                  onTap: widget.onGoToProducts,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: theme.softShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            b['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: theme.primaryGreen,
                              child: Center(
                                child: Icon(
                                  Icons.agriculture_rounded,
                                  color: theme.onImage,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  theme.imageOverlayStrong,
                                  theme.imageOverlay.withValues(alpha: 0.15),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: theme.accentOrange,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'TANI MART PROMO',
                                    style: GoogleFonts.poppins(
                                      color: theme.onPrimary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  b['title']!,
                                  style: GoogleFonts.poppins(
                                    color: theme.onImage,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['subtitle']!,
                                  style: GoogleFonts.poppins(
                                    color: theme.onImage.withValues(alpha: 0.9),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIndex == i ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _bannerIndex == i ? theme.primaryGreen : theme.borderColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(AppColors theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Produk',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              InkWell(
                onTap: widget.onGoToProducts,
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.primaryGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: context.watch<ProductProvider>().categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              final cat = context.read<ProductProvider>().categories[i];
              return InkWell(
                onTap: () => _navigateToCatalog(category: cat),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor),
                        boxShadow: theme.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          ProductImages.getCategoryAsset(cat),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.category_rounded,
                            color: theme.primaryGreen,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 66,
                      child: Text(
                        cat,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: theme.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, AppColors theme,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, color: theme.primaryGreen, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductHorizontalList(List<Product> products, AppColors theme) {
    if (products.isEmpty) {
      return SizedBox(
        height: 50,
        child: Center(
          child: Text('Belum ada produk untuk kategori ini.',
              style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        ),
      );
    }
    return SizedBox(
      height: 275,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        itemBuilder: (ctx, i) => SizedBox(
          width: 170,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ProductCard(
              product: products[i],
              theme: theme,
              onTap: () => _openDetail(products[i]),
              onAddToCart: () => _addToCart(products[i]),
              compact: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String message, AppColors theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            size: 52,
            color: theme.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: theme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => context.read<ProductProvider>().refresh(),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _openDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          initialProduct: product,
        ),
      ),
    );
  }

  void _addToCart(Product product) async {
    final theme = AppColors.of(context);
    if (!product.tersedia || product.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk tidak tersedia atau stok telah habis.'),
          backgroundColor: theme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      final success = await context.read<CartProvider>().addItem(product.id, 1);
      if (!mounted) return;
      if (success) {
        NotificationService.cartCountNotifier.value++;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.nama} berhasil masuk ke keranjang! 🛒'),
            backgroundColor: theme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        final error = context.read<CartProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal menambahkan ke keranjang.'),
            backgroundColor: theme.errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan jaringan: $error'),
          backgroundColor: theme.errorRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool compact;
  final AppColors theme;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.compact = false,
    required this.theme,
  });

  String _formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final isAvailable = product.tersedia && product.stok > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.borderColor, width: 0.8),
          boxShadow: theme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(
                      imageUrl: product.foto,
                      productName: product.nama,
                      category: product.kategori,
                      fit: BoxFit.cover,
                    ),
                    if (!isAvailable)
                      Container(
                        color: theme.imageOverlay,
                        child: Center(
                          child: Text(
                            'Stok Habis',
                            style: TextStyle(
                              color: theme.onImage,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    if (product.mudahRusak)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.accentOrange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Segar',
                            style: TextStyle(
                              color: theme.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.kategori,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: theme.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.nama,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w600,
                        color: theme.textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatRupiah(product.harga),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '/${product.satuanJual}',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: FilledButton(
                        onPressed: isAvailable ? onAddToCart : null,
                        style: FilledButton.styleFrom(
            backgroundColor: AppColors.of(context).primaryGreen,
                          disabledBackgroundColor: theme.borderColor,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isAvailable
                                  ? Icons.add_shopping_cart
                                  : Icons.remove_shopping_cart_outlined,
                              size: 13,
                              color: isAvailable
                                  ? theme.onPrimary
                                  : theme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAvailable ? '+ Keranjang' : 'Habis',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? theme.onPrimary
                                    : theme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircularProgressIndicator(color: theme.primaryGreen),
          const SizedBox(height: 12),
          Text(
            'Memuat produk segar Tani Mart...',
            style: GoogleFonts.poppins(color: theme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
