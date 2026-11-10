import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/cart_actions.dart';
import '../core/utils/ui.dart';
import '../models/category.dart' as category_model;
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_search_field.dart';
import '../widgets/product_card.dart';
import '../widgets/product_image.dart';
import '../widgets/section_header.dart';
import '../widgets/state_views.dart';
import 'product_detail_page.dart';

/// Beranda: sapaan, pencarian, kategori, produk terbaru, dan semuanya.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) await context.read<ProductProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openCatalog({String? category, String query = ''}) {
    context.read<ProductProvider>().setFilter(category: category, query: query);
    context.read<NavigationProvider>().select(AppTab.products);
  }

  Future<void> _refresh() async {
    final error = await context.read<ProductProvider>().refresh();
    if (!mounted) return;
    context.read<CartProvider>().loadIfStale();
    if (error != null) showAppSnack(context, error, error: true);
  }

  void _open(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          productId: product.id,
          initialProduct: product,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = context.select<ProductProvider, List<Product>>((p) => p.all);
    final categories = context.select<ProductProvider, List<category_model.ProductCategory>>(
      (p) => p.categories,
    );
    final isLoading = context.select<ProductProvider, bool>((p) => p.isLoading);
    final hasLoaded = context.select<ProductProvider, bool>((p) => p.hasLoaded);
    final error = context.select<ProductProvider, String?>((p) => p.errorMessage);
    final isOffline = context.select<ProductProvider, bool>((p) => p.isOffline);
    final firstName = context.select<AuthProvider, String>((a) => a.firstName);
    final cart = context.watch<CartProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    final latest = products.where((e) => e.isAvailable).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    final latestRow = latest.take(6).toList();
    final gridProducts = products.take(8).toList();

    Widget content;
    if (!_hasLoaded(products, isLoading, hasLoaded, error)) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: LoadingView(),
      );
    } else if (products.isEmpty && error != null) {
      content = SliverFillRemaining(
        hasScrollBody: false,
        child: ErrorView(
          message: error,
          scrollable: false,
          onRetry: () => context.read<ProductProvider>().refresh(),
        ),
      );
    } else if (products.isEmpty && hasLoaded) {
      content = const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyView(
          icon: Icons.storefront_outlined,
          title: 'Belum ada produk',
          message: 'Produk akan tampil di sini setelah ditambahkan oleh toko.',
          scrollable: false,
        ),
      );
    } else {
      content = SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Produk Terbaru',
              onAction: () => _openCatalog(),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: ProductCard.extentFor(158, 1),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: latestRow.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final product = latestRow[index];
                  return SizedBox(
                    width: 158,
                    child: ProductCard(
                      key: ValueKey<int>(product.id),
                      product: product,
                      adding: cart.isAdding(product.id),
                      onTap: () => _open(product),
                      onAdd: () => addProductToCart(context, product),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Semua Produk',
              onAction: () => _openCatalog(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverProductGrid(
              products: gridProducts,
              onOpen: _open,
              onAdd: (product) => addProductToCart(context, product),
              isAdding: cart.isAdding,
            ),
          ),
        ],
      );
    }

    final offlineBanner = isOffline
        ? SliverToBoxAdapter(
            child: Container(
              color: p.warningSoft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.wifi_off_rounded, size: 16, color: p.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mode offline — menampilkan data tersimpan terakhir.',
                      style: text.bodySmall?.copyWith(color: p.warning),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SliverToBoxAdapter(child: SizedBox.shrink());

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              offlineBanner,
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppLogo(size: 34),
                      const SizedBox(height: 16),
                      Text(
                        'Halo, $firstName',
                        style: text.bodyMedium?.copyWith(
                          color: p.textSecondary,
                        ),
                      ),
                      Text('Belanja Segar\nuntuk Keluarga', style: text.headlineSmall),
                      const SizedBox(height: 14),
                      AppSearchField(
                        controller: _search,
                        hint: 'Cari produk di TaniMart...',
                        onSubmitted: (value) =>
                            _openCatalog(query: value.trim()),
                      ),
                      const SizedBox(height: 16),
                      _PromoBanner(onTap: () => _openCatalog()),
                    ],
                  ),
                ),
              ),
              if (categories.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return _CategoryItem(
                            category: category,
                            onTap: () =>
                                _openCatalog(category: category.nama),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              content,
            ],
          ),
        ),
      ),
    );
  }

  bool _hasLoaded(List<Product> products, bool isLoading, bool hasLoaded, String? error) {
    if (!hasLoaded && isLoading) return false;
    if (products.isNotEmpty) return true;
    if (hasLoaded) return true;
    if (error != null) return true;
    return false;
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Material(
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.brand, BrandColors.deep],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -24,
                top: -24,
                child: Icon(
                  Icons.eco_rounded,
                  size: 140,
                  color: p.onBrand.withValues(alpha: 0.14),
                ),
              ),
              Positioned(
                right: 18,
                bottom: 14,
                child: Icon(
                  Icons.shopping_basket_rounded,
                  size: 54,
                  color: p.onBrand.withValues(alpha: 0.9),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Segar dari Petani\nLangsung ke Rumah',
                      style: text.titleLarge?.copyWith(color: p.onBrand),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sayur, buah, dan kebutuhan harian',
                      style: text.bodySmall?.copyWith(
                        color: p.onBrand.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: p.onBrand,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Belanja Sekarang',
                            style: text.labelMedium?.copyWith(
                              color: BrandColors.deep,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: BrandColors.deep,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, required this.onTap});

  final category_model.ProductCategory category;
  final VoidCallback onTap;

  static IconData iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('sayur')) return Icons.eco_rounded;
    if (n.contains('buah')) return Icons.local_florist_rounded;
    if (n.contains('bibit') || n.contains('benih')) return Icons.spa_rounded;
    if (n.contains('pupuk')) return Icons.grass_rounded;
    if (n.contains('alat')) return Icons.agriculture_rounded;
    if (n.contains('pangan') || n.contains('sembako') || n.contains('harian')) {
      return Icons.rice_bowl_rounded;
    }
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = iconFor(category.nama);

    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.brandSoft,
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: category.gambar == null || category.gambar!.isEmpty
                  ? Icon(icon, color: p.brandText, size: 26)
                  : ClipOval(
                      child: ProductImage(
                        url: category.gambar,
                        width: 56,
                        height: 56,
                        cacheWidth: 112,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            Text(
              category.nama,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
