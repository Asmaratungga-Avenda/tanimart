import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/product_images.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail_page.dart';
import 'product_catalog_page.dart';

/// Halaman Beranda AgriMart
/// Konsep Desain: FRESH MARKET — MODERN AGRICULTURE
class HomePage extends StatefulWidget {
  final VoidCallback? onGoToCart;
  final VoidCallback? onGoToProducts;

  const HomePage({super.key, this.onGoToCart, this.onGoToProducts});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMsg;
  int _bannerIndex = 0;
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;
  final TextEditingController _searchController = TextEditingController();

  static const _primaryGreen = AppTheme.primaryGreen;
  static const _lightGreen = AppTheme.lightGreen;
  static const _bgColor = AppTheme.background;
  static const _textPrimary = AppTheme.textPrimary;
  static const _textSecondary = AppTheme.textSecondary;

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

  final List<Map<String, String>> _categories = [
    {
      'image': ProductImages.catSayuran,
      'label': 'Sayuran',
      'filter': 'Sayuran',
    },
    {
      'image': ProductImages.catBuah,
      'label': 'Buah Segar',
      'filter': 'Buah',
    },
    {
      'image': ProductImages.catBibit,
      'label': 'Bibit & Benih',
      'filter': 'Bibit',
    },
    {
      'image': ProductImages.catPupuk,
      'label': 'Pupuk',
      'filter': 'Pupuk',
    },
    {
      'image': ProductImages.catAlatPertanian,
      'label': 'Alat Tani',
      'filter': 'Alat',
    },
    {
      'image': ProductImages.catKebutuhanHarian,
      'label': 'Kebutuhan Harian',
      'filter': 'Sembako',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
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

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final result = await ApiService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMsg = 'Gagal memuat data produk dari server.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    super.dispose();
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
    // Filter produk untuk seksi-seksi beranda
    final featuredProducts =
        _products.where((p) => p.tersedia && p.stok > 0).take(6).toList();
    final bestSellingProducts = _products.reversed.take(6).toList();
    final agriculturalProducts = _products.where((p) {
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
    final dailyNecessities = _products.where((p) {
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
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        color: _primaryGreen,
        onRefresh: _fetchProducts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Header Greeting & Branding
            SliverToBoxAdapter(child: _buildGreetingHeader()),

            // 2. Search Bar
            SliverToBoxAdapter(child: _buildSearchBar()),

            // 3. Promotional Banners Carousel
            SliverToBoxAdapter(child: _buildBannerCarousel()),

            // 4. Product Categories
            SliverToBoxAdapter(child: _buildCategorySection()),

            if (_isLoading)
              const SliverToBoxAdapter(child: _LoadingSkeleton())
            else if (_errorMsg != null)
              SliverToBoxAdapter(child: _buildError())
            else ...[
              // 5. Featured Products (Produk Rekomendasi)
              if (featuredProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Produk Rekomendasi',
                    Icons.star_rounded,
                    onSeeAll: widget.onGoToProducts,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(featuredProducts),
                ),
              ],

              // 6. Best-Selling Products (Produk Terlaris)
              if (bestSellingProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Produk Terlaris',
                    Icons.local_fire_department_rounded,
                    onSeeAll: widget.onGoToProducts,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(bestSellingProducts),
                ),
              ],

              // 7. Agricultural Products (Produk Pertanian & Segar)
              if (agriculturalProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Produk Pertanian Segar',
                    Icons.eco_rounded,
                    onSeeAll: () =>
                        _navigateToCatalog(category: 'Sayuran dan Buah Segar'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(agriculturalProducts),
                ),
              ],

              // 8. Daily Necessities (Sembako & Kebutuhan Harian)
              if (dailyNecessities.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _buildSectionHeader(
                    'Kebutuhan Harian & Sembako',
                    Icons.shopping_basket_rounded,
                    onSeeAll: () => _navigateToCatalog(
                        category: 'Sembako dan Kebutuhan Harian'),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildProductHorizontalList(dailyNecessities),
                ),
              ],

              // 9. All Products Grid (Semua Produk)
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  'Katalog Lengkap',
                  Icons.grid_view_rounded,
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
                      product: _products[i],
                      onTap: () => _openDetail(_products[i]),
                      onAddToCart: () => _addToCart(_products[i]),
                    ),
                    childCount: _products.length,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: _primaryGreen,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
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
                      'Selamat Datang di AgriMart 👋',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kebutuhan Pertanian dan Harian dalam Satu Genggaman',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.88),
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
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Colors.white,
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              _navigateToCatalog(query: query.trim());
            }
          },
          decoration: InputDecoration(
            hintText: 'Cari produk pertanian atau kebutuhan harian...',
            hintStyle: GoogleFonts.poppins(
              color: _textSecondary,
              fontSize: 12.5,
            ),
            prefixIcon: const Icon(Icons.search, color: _primaryGreen, size: 22),
            suffixIcon: IconButton(
              icon: const Icon(Icons.tune_rounded, color: _primaryGreen, size: 20),
              tooltip: 'Buka Katalog & Filter',
              onPressed: () => _navigateToCatalog(
                query: _searchController.text.trim().isEmpty
                    ? null
                    : _searchController.text.trim(),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerCarousel() {
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
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
                              color: _primaryGreen,
                              child: const Center(
                                child: Icon(Icons.agriculture_rounded,
                                    color: Colors.white, size: 40),
                              ),
                            ),
                          ),
                          // Subtle dark overlay for text contrast
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withValues(alpha: 0.65),
                                  Colors.black.withValues(alpha: 0.15),
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
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'AGRIMART PROMO',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  b['title']!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  b['subtitle']!,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white.withValues(alpha: 0.9),
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
                  color: _bannerIndex == i ? _primaryGreen : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
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
                  color: _textPrimary,
                ),
              ),
              InkWell(
                onTap: widget.onGoToProducts,
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _primaryGreen,
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
            itemCount: _categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              return InkWell(
                onTap: () => _navigateToCatalog(category: cat['filter']),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          cat['image']!,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.category_rounded,
                            color: _primaryGreen,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: 66,
                      child: Text(
                        cat['label']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
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

  Widget _buildSectionHeader(String title, IconData icon,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: _primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductHorizontalList(List<Product> products) {
    if (products.isEmpty) {
      return const SizedBox(
        height: 50,
        child: Center(
          child: Text('Belum ada produk untuk kategori ini.',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
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
              onTap: () => _openDetail(products[i]),
              onAddToCart: () => _addToCart(products[i]),
              compact: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _errorMsg ?? 'Gagal memuat produk dari server.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _fetchProducts,
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
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
  }

  void _addToCart(Product product) async {
    if (!product.tersedia || product.stok <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk tidak tersedia atau stok telah habis.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    try {
      await ApiService.addCart(product.id, 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.nama} berhasil masuk ke keranjang! 🛒'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ───────── Product Card Widget ─────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool compact;

  static const _primaryGreen = AppTheme.primaryGreen;
  static const _textPrimary = AppTheme.textPrimary;
  static const _textSecondary = AppTheme.textSecondary;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
    this.compact = false,
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with 1:1 Aspect Ratio per Section 8
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
                        color: Colors.black.withValues(alpha: 0.5),
                        child: const Center(
                          child: Text(
                            'Stok Habis',
                            style: TextStyle(
                              color: Colors.white,
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
                            color: const Color(0xFFF59E0B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Segar',
                            style: TextStyle(
                              color: Colors.white,
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

            // Info details
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
                        color: _primaryGreen,
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
                        color: _textPrimary,
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
                            color: _primaryGreen,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '/${product.satuanJual}',
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            color: _textSecondary,
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
                          backgroundColor: _primaryGreen,
                          disabledBackgroundColor: Colors.grey.shade200,
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
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAvailable ? '+ Keranjang' : 'Habis',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isAvailable
                                    ? Colors.white
                                    : Colors.grey.shade500,
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircularProgressIndicator(color: AppTheme.primaryGreen),
          const SizedBox(height: 12),
          Text(
            'Memuat produk segar AgriMart...',
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
