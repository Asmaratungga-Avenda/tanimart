import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/theme_extension.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/notification_service.dart';
import 'product_detail_page.dart';

class ProductCatalogPage extends StatefulWidget {
  final String? initialCategory;
  final String? initialQuery;
  final bool showBackButton;

  const ProductCatalogPage({
    super.key,
    this.initialCategory,
    this.initialQuery,
    this.showBackButton = false,
  });

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  String _searchQuery = '';
  late final TextEditingController _searchController;



  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final provider = context.read<ProductProvider>();
      await provider.loadCategories();
      if (!mounted) return;
      if (widget.initialCategory != null) {
        final query = widget.initialCategory!.toLowerCase().replaceAll(' & ', ' ');
        String? match;
        for (final category in provider.categories) {
          if (category.toLowerCase().contains(query) || query.contains(category.toLowerCase())) {
            match = category;
            break;
          }
        }
        provider.setCategory(match);
      }
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts({String? sortBy}) async {
    final provider = context.read<ProductProvider>();
    await provider.loadProducts(
      kategori: provider.selectedCategory == 'Semua' ? null : provider.selectedCategory,
      cari: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      sortBy: sortBy,
    );
  }

  List<Product> get _sortedProducts {
    final provider = context.read<ProductProvider>();
    return provider.products;
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.of(context);
    final provider = context.watch<ProductProvider>();
    final selectedCategory = provider.selectedCategory ?? 'Semua';
    final products = _sortedProducts;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textPrimary,
        elevation: 0,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(
          'Produk',
          style: GoogleFonts.poppins(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: theme.textPrimary),
            tooltip: 'Urutkan',
            onSelected: (value) async {
              await _loadProducts(sortBy: value);
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
          _buildSearchAndFilter(theme, selectedCategory),
          _buildCategoryChips(theme, selectedCategory),
          Expanded(child: _buildBody(provider, products, theme)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(AppColors theme, String selectedCategory) {
    return Container(
      color: theme.primaryGreen,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.poppins(fontSize: 14, color: theme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Cari produk...',
          hintStyle: GoogleFonts.poppins(color: theme.textSecondary, fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: theme.primaryGreen, size: 20),
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
          fillColor: theme.surfaceColor,
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

  Widget _buildCategoryChips(AppColors theme, String selectedCategory) {
    return Container(
      height: 48,
      color: theme.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: context.watch<ProductProvider>().categories.length + 1,
        itemBuilder: (ctx, i) {
          final categories = context.read<ProductProvider>().categories;
          final cat = i == 0 ? 'Semua' : categories[i - 1];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(
                cat,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? theme.primaryGreen : theme.textSecondary,
                ),
              ),
              selected: isSelected,
              onSelected: (_) async {
                context.read<ProductProvider>().setCategory(cat);
                await _loadProducts();
              },
              backgroundColor: theme.surfaceColor,
              selectedColor: theme.lightGreen,
              checkmarkColor: theme.primaryGreen,
              side: BorderSide(
                color: isSelected ? theme.primaryGreen : theme.borderColor,
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

  Widget _buildBody(ProductProvider provider, List<Product> sorted, AppColors theme) {
    if (provider.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryGreen),
      );
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 60, color: theme.textSecondary),
              const SizedBox(height: 12),
              Text(
                provider.errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: theme.textSecondary),
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
                  color: theme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Coba kata kunci atau kategori lain',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: theme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: theme.primaryGreen,
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
                    fontSize: 12, color: theme.textSecondary),
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
                  theme: theme,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailPage(
                        productId: sorted[i].id,
                        initialProduct: sorted[i],
                      ),
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
        SnackBar(
          content: Text('Produk tidak tersedia atau stok habis.'),
          backgroundColor: AppColors.of(context).errorRed,
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
            content: Text('${product.nama} ditambahkan ke keranjang 🛒'),
            backgroundColor: AppColors.of(context).primaryGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        final error = context.read<CartProvider>().errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Gagal menambahkan ke keranjang.'),
            backgroundColor: AppColors.of(context).errorRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan jaringan.'),
          backgroundColor: AppColors.of(context).errorRed,
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
  final AppColors theme;

  const _CatalogProductCard({
    required this.product,
    required this.theme,
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
                              color: theme.onPrimary,
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
                              color: Theme.of(context).colorScheme.onTertiary,
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
                        fontSize: 12.5,
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
                    Text(
                      'Stok: ${product.stok}',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: FilledButton(
                        onPressed: isAvailable ? onAddToCart : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.primaryGreen,
                          disabledBackgroundColor: theme.borderColor,
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
                                ? theme.onPrimary
                                : theme.textSecondary,
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
