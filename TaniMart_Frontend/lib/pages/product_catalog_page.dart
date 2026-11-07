import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'product_detail_page.dart';

class ProductCatalogPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuery;

  const ProductCatalogPage({super.key, this.initialCategory, this.initialQuery});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMsg;

  String _selectedCategory = 'Semua';
  String _sortBy = 'default';
  late final TextEditingController _searchController;
  String _searchQuery = '';

  static const _primaryGreen = AppTheme.primaryGreen;
  static const _lightGreen = AppTheme.lightGreen;
  static const _textPrimary = AppTheme.textPrimary;
  static const _textSecondary = AppTheme.textSecondary;

  final List<String> _categories = [
    'Semua',
    'Sayuran dan Buah Segar',
    'Sembako dan Kebutuhan Harian',
    'Sayuran',
    'Beras & Biji-bijian',
    'Bumbu & Rempah',
    'Bibit & Benih',
    'Pupuk',
    'Peralatan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);

    if (widget.initialCategory != null) {
      final match = _categories.firstWhere(
        (c) => c.toLowerCase().contains(
            widget.initialCategory!.toLowerCase().replaceAll(' & ', ' ')),
        orElse: () => 'Semua',
      );
      _selectedCategory = match;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final result = await ApiService.getProducts(
        kategori: _selectedCategory == 'Semua' ? null : _selectedCategory,
        cari: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
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

  List<Product> get _sortedProducts {
    final list = List<Product>.from(_products);
    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.harga.compareTo(b.harga));
        break;
      case 'price_desc':
        list.sort((a, b) => b.harga.compareTo(a.harga));
        break;
      case 'name':
        list.sort((a, b) => a.nama.compareTo(b.nama));
        break;
      default:
        break;
    }
    return list;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Produk',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.white),
            tooltip: 'Urutkan',
            onSelected: (value) {
              setState(() => _sortBy = value);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'default', child: Text('Default')),
              const PopupMenuItem(value: 'price_asc', child: Text('Harga: Rendah → Tinggi')),
              const PopupMenuItem(value: 'price_desc', child: Text('Harga: Tinggi → Rendah')),
              const PopupMenuItem(value: 'name', child: Text('Nama A-Z')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildCategoryChips(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      color: _primaryGreen,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14, color: _textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: GoogleFonts.poppins(color: _textSecondary, fontSize: 14),
          prefixIcon:
              const Icon(Icons.search, color: Color(0xFF2E7D32), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _loadProducts();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onSubmitted: (val) {
          setState(() => _searchQuery = val);
          _loadProducts();
        },
        onChanged: (val) {
          if (val.isEmpty) {
            setState(() => _searchQuery = '');
            _loadProducts();
          }
        },
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 48,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? _primaryGreen : _textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedCategory = cat);
                _loadProducts();
              },
              backgroundColor: Colors.white,
              selectedColor: _lightGreen,
              checkmarkColor: _primaryGreen,
              side: BorderSide(
                color: isSelected ? _primaryGreen : Colors.grey.shade300,
              ),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _primaryGreen),
      );
    }
    if (_errorMsg != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _errorMsg!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: _textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final sorted = _sortedProducts;
    if (sorted.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 12),
            Text(
              'Produk tidak ditemukan',
              style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba kata kunci atau kategori lain',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _loadProducts,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 4),
              child: Text(
                '${sorted.length} produk ditemukan',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: _textSecondary),
              ),
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.62,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: sorted.length,
                itemBuilder: (ctx, i) => _CatalogProductCard(
                  product: sorted[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(product: sorted[i]),
                    ),
                  ),
                  onAddToCart: () => _addToCart(sorted[i]),
                ),
              ),
            ),
          ],
        ),
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
          content: Text('${product.nama} ditambahkan ke keranjang 🛒'),
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

class _CatalogProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  static const _primaryGreen = AppTheme.primaryGreen;
  static const _textPrimary = AppTheme.textPrimary;
  static const _textSecondary = AppTheme.textSecondary;

  const _CatalogProductCard({
    required this.product,
    required this.onTap,
    required this.onAddToCart,
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
                        fontSize: 12.5,
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
                    Text(
                      'Stok: ${product.stok}',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: _textSecondary,
                      ),
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
                        child: Text(
                          isAvailable ? '+ Keranjang' : 'Habis',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isAvailable
                                ? Colors.white
                                : Colors.grey.shade500,
                          ),
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

