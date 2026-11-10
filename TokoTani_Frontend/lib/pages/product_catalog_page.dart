import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
  bool _isSearching = false;

  List<String> get _categories {
    final values = context.read<ProductProvider>().products
        .map((product) => product.kategori.trim())
        .where((category) => category.isNotEmpty)
        .toSet()
        .toList()..sort();
    return ['Semua', ...values];
  }

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialQuery ?? '';
    _searchController = TextEditingController(text: _searchQuery);
    _isSearching = _searchQuery.isNotEmpty;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.initialCategory != null) {
        final match = _categories.firstWhere(
          (category) => category.toLowerCase().contains(
            widget.initialCategory!.toLowerCase().replaceAll(' & ', ' '),
          ),
          orElse: () => 'Semua',
        );
        context.read<ProductProvider>().setCategory(match);
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
      kategori: provider.selectedCategory == 'Semua'
          ? null
          : provider.selectedCategory,
      cari: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      sortBy: sortBy,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<ProductProvider>();
    final selectedCategory = provider.selectedCategory ?? 'Semua';
    final products = provider.products;

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.6)),
                ),
                onSubmitted: (val) {
                  setState(() => _searchQuery = val);
                  _loadProducts();
                },
              )
            : Text(
                'Semua Produk',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                  _loadProducts();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCategoryChips(colors, selectedCategory),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadProducts(),
              child: _buildBody(provider, products, colors, theme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme colors, String selectedCategory) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final cat = _categories[i];
          final isSelected = selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (_) async {
                context.read<ProductProvider>().setCategory(cat);
                await _loadProducts();
              },
              selectedColor: colors.primary,
              labelStyle: GoogleFonts.poppins(
                color: isSelected ? Colors.white : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(ProductProvider provider, List<Product> products, ColorScheme colors, ThemeData theme) {
    if (provider.isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null && products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _loadProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🌿', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            Text(
              'Produk tidak ditemukan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Coba kata kunci atau kategori lain',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final product = products[i];
        return _ProductCard(
          product: product,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(
                productId: product.id,
                initialProduct: product,
              ),
            ),
          ),
          onAdd: () async {
            final ok = await context.read<CartProvider>().addItem(product.id, 1);
            if (!mounted) return;
            if (ok) {
              NotificationService.cartCountNotifier.value++;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.nama} ditambahkan ke keranjang 🛒'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAvailable = product.tersedia && product.stok > 0;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: ProductImage(
                      imageUrl: product.foto,
                      productName: product.nama,
                      category: product.kategori,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  if (!isAvailable)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(
                        child: Text(
                          'Stok Habis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  if (product.mudahRusak)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Segar',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.kategori,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.nama,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Rp ${_rupiah(product.harga)}',
                              style: GoogleFonts.poppins(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '/${product.satuanJual}',
                              style: GoogleFonts.poppins(
                                color: colors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: isAvailable ? onAdd : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isAvailable ? colors.primary : colors.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isAvailable ? Icons.add : Icons.block,
                            color: Colors.white,
                            size: 20,
                          ),
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
