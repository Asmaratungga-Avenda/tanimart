import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/cart_actions.dart';
import '../core/utils/ui.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/app_search_field.dart';
import '../widgets/filter_pill.dart';
import '../widgets/product_card.dart';
import '../widgets/state_views.dart';
import 'product_detail_page.dart';

/// Katalog: pencarian, filter kategori, urutan, dan grid dua kolom.
class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  late final ProductProvider _provider;
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ProductProvider>();
    _search = TextEditingController(text: _provider.query);
    _provider.addListener(_syncQuery);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _provider.ensureLoaded();
    });
  }

  @override
  void dispose() {
    _provider.removeListener(_syncQuery);
    _search.dispose();
    super.dispose();
  }

  /// Filter bisa diubah dari Beranda; samakan kolom pencarian.
  void _syncQuery() {
    if (_search.text != _provider.query) _search.text = _provider.query;
  }

  Future<void> _refresh() async {
    final error = await _provider.load();
    if (error != null && mounted) showAppSnack(context, error, error: true);
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
    final provider = context.watch<ProductProvider>();
    final cart = context.watch<CartProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final items = provider.filtered;
    final categories = provider.categories;

    Widget body;
    if (provider.all.isEmpty && provider.isLoading) {
      body = const LoadingView();
    } else if (provider.all.isEmpty && provider.errorMessage != null) {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ErrorView(message: provider.errorMessage!, onRetry: _refresh),
      );
    } else if (provider.all.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: const EmptyView(
          icon: Icons.storefront_outlined,
          title: 'Belum ada produk',
          message: 'Produk akan tampil di sini setelah ditambahkan oleh toko.',
        ),
      );
    } else if (items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: EmptyView(
          icon: Icons.search_off_rounded,
          title: 'Produk tidak ditemukan',
          message: 'Coba kata kunci lain atau hapus filter kategori.',
          actionLabel: 'Hapus Filter',
          onAction: provider.clearFilter,
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverProductGrid(
                products: items,
                onOpen: _open,
                onAdd: (product) => addProductToCart(context, product),
                isAdding: cart.isAdding,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        titleSpacing: widget.showBackButton ? 0 : 16,
        title: const Text('Semua Produk'),
        actions: [
          PopupMenuButton<ProductSort>(
            tooltip: 'Urutkan',
            icon: const Icon(Icons.swap_vert_rounded),
            initialValue: provider.sort,
            onSelected: provider.setSort,
            itemBuilder: (_) => const [
              PopupMenuItem(value: ProductSort.none, child: Text('Bawaan')),
              PopupMenuItem(
                value: ProductSort.priceAsc,
                child: Text('Harga terendah'),
              ),
              PopupMenuItem(
                value: ProductSort.priceDesc,
                child: Text('Harga tertinggi'),
              ),
              PopupMenuItem(value: ProductSort.name, child: Text('Nama A-Z')),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: AppSearchField(
              controller: _search,
              onChanged: provider.setQuery,
            ),
          ),
          if (categories.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return FilterPill(
                      label: 'Semua',
                      selected: provider.category == null,
                      onTap: () => provider.setCategory(null),
                    );
                  }
                  final name = categories[index - 1];
                  return FilterPill(
                    label: name,
                    selected: provider.category?.toLowerCase() ==
                        name.toLowerCase(),
                    onTap: () => provider.setCategory(name),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${items.length} produk',
                style: text.bodySmall?.copyWith(color: p.textSecondary),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
