import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail_page.dart';
import 'product_catalog_page.dart';

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

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _bgColor = Color(0xFFF7F9F6);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Panen Segar\nLangsung ke Pintu',
      'subtitle': 'Belanja produk pertanian berkualitas',
      'emoji': '🌿',
      'color': const Color(0xFF2E7D32),
      'accent': const Color(0xFF4CAF50),
    },
    {
      'title': 'Diskon Produk\nOrganik Hari Ini',
      'subtitle': 'Hemat hingga 30% untuk produk pilihan',
      'emoji': '🌾',
      'color': const Color(0xFF1565C0),
      'accent': const Color(0xFF1976D2),
    },
    {
      'title': 'Gratis Ongkir\nPembelian ≥ Rp 100.000',
      'subtitle': 'Berlaku untuk wilayah tertentu',
      'emoji': '🚜',
      'color': const Color(0xFFE65100),
      'accent': const Color(0xFFF57C00),
    },
  ];

  final List<Map<String, String>> _categories = [
    {'icon': '🌾', 'label': 'Beras\n& Biji'},
    {'icon': '🥬', 'label': 'Sayuran'},
    {'icon': '🌶️', 'label': 'Bumbu\n& Rempah'},
    {'icon': '🌱', 'label': 'Bibit\n& Benih'},
    {'icon': '🧪', 'label': 'Pupuk'},
    {'icon': '🛠️', 'label': 'Peralatan'},
    {'icon': '🧴', 'label': 'Kebutuhan\nHarian'},
    {'icon': '📦', 'label': 'Lainnya'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = (_bannerIndex + 1) % _banners.length;
      if (_bannerController.hasClients) {
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
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
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: RefreshIndicator(
        color: _primaryGreen,
        onRefresh: _fetchProducts,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildGreetingHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildBanner()),
            SliverToBoxAdapter(child: _buildCategorySection()),
            if (_isLoading)
              const SliverToBoxAdapter(child: _LoadingProductsGrid())
            else if (_errorMsg != null)
              SliverToBoxAdapter(child: _buildError())
            else ...[
              SliverToBoxAdapter(
                child: _buildSectionHeader('Produk Rekomendasi', '🌟',
                    onSeeAll: widget.onGoToProducts),
              ),
              SliverToBoxAdapter(
                child: _buildProductHorizontalList(
                  _products.where((p) => p.tersedia && p.stok > 0).take(6).toList(),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader('Produk Terbaru', '🆕',
                    onSeeAll: widget.onGoToProducts),
              ),
              SliverToBoxAdapter(
                child: _buildProductHorizontalList(
                  _products.reversed.take(6).toList(),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildSectionHeader('Semua Produk', '📦',
                    onSeeAll: widget.onGoToProducts),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
      color: _primaryGreen,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Text('🌿', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tani Mart',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Kebutuhan Pertanian & Harian',
                  style: GoogleFonts.poppins(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onGoToCart,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_cart_outlined,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: widget.onGoToProducts,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: _textSecondary.withValues(alpha: 0.6), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cari produk pertanian...',
                style: GoogleFonts.poppins(
                  color: _textSecondary,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _lightGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: _primaryGreen, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _banners.length,
              onPageChanged: (i) => setState(() => _bannerIndex = i),
              itemBuilder: (ctx, i) {
                final b = _banners[i];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [b['color'] as Color, b['accent'] as Color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              b['title'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              b['subtitle'] as String,
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Belanja Sekarang',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        b['emoji'] as String,
                        style: const TextStyle(fontSize: 56),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIndex == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _bannerIndex == i
                      ? _primaryGreen
                      : _primaryGreen.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'Kategori Produk',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
        ),
        SizedBox(
          height: 86,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final catName = cat['label']!.replaceAll('\n', ' & ').trim();
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductCatalogPage(
                        initialCategory: catName,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 72,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(cat['icon']!, style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(
                        cat['label']!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: GoogleFonts.poppins(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w500,
                          color: _textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, String emoji,
      {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'Lihat Semua',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _primaryGreen,
                  fontWeight: FontWeight.w600,
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
        height: 60,
        child: Center(
          child: Text('Belum ada produk tersedia',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return SizedBox(
      height: 255,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: products.length,
        itemBuilder: (ctx, i) => SizedBox(
          width: 160,
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
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            _errorMsg ?? 'Gagal memuat produk.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _fetchProducts,
            icon: const Icon(Icons.refresh),
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
    if (!product.tersedia || product.stok == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produk tidak tersedia atau stok habis.'),
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
          content: Text('${product.nama} berhasil ditambahkan ke keranjang! 🛒'),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildImage(),
                    if (!isAvailable)
                      Container(
                        color: Colors.black.withValues(alpha: 0.45),
                        child: const Center(
                          child: Text(
                            'Habis',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
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
                            color: Colors.orange.shade700,
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
            // Info
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.kategori,
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: _primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.nama,
                      style: GoogleFonts.poppins(
                        fontSize: compact ? 11.5 : 12.5,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      _formatRupiah(product.harga),
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                    Text(
                      '/ ${product.satuanJual}',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: _textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 30,
                      child: FilledButton(
                        onPressed: isAvailable ? onAddToCart : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          disabledBackgroundColor: Colors.grey.shade200,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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
                                fontSize: 9.5,
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

  Widget _buildImage() {
    if (product.foto != null && product.foto!.startsWith('http')) {
      return Image.network(
        product.foto!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholderImage(),
        loadingBuilder: (_, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFE8F5E9),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2E7D32),
              ),
            ),
          );
        },
      );
    }
    return _placeholderImage();
  }

  Widget _placeholderImage() {
    final emoji = _emojiForCategory(product.kategori);
    return Container(
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 44)),
      ),
    );
  }

  String _emojiForCategory(String kategori) {
    final k = kategori.toLowerCase();
    if (k.contains('beras') || k.contains('biji')) {
      return '🌾';
    }
    if (k.contains('sayur')) {
      return '🥬';
    }
    if (k.contains('bumbu') || k.contains('rempah') || k.contains('cabai')) {
      return '🌶️';
    }
    if (k.contains('buah')) {
      return '🍅';
    }
    if (k.contains('bibit') || k.contains('benih')) {
      return '🌱';
    }
    if (k.contains('pupuk')) {
      return '🧪';
    }
    if (k.contains('alat') || k.contains('peralatan')) {
      return '🛠️';
    }
    if (k.contains('harian')) {
      return '🧴';
    }
    return '🌿';
  }
}

// ───────── Loading Skeleton ─────────

class _LoadingProductsGrid extends StatelessWidget {
  const _LoadingProductsGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              _skeletonBox(100, 20),
              const Spacer(),
              _skeletonBox(70, 14),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (_, _) => _buildSkeletonCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skeletonBox(60, 10),
                  const SizedBox(height: 4),
                  _skeletonBox(double.infinity, 12),
                  const Spacer(),
                  _skeletonBox(80, 14),
                  const SizedBox(height: 6),
                  _skeletonBox(double.infinity, 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

