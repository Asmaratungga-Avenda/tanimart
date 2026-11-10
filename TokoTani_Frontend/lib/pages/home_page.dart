import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../services/notification_service.dart';
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
  String _category = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _open(Product product) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductDetailPage(productId: product.id, initialProduct: product)),
  );

  Future<void> _add(Product product) async {
    if (!product.tersedia || product.stok < 1) {
      _message('Produk sedang tidak tersedia.');
      return;
    }
    final ok = await context.read<CartProvider>().addItem(product.id, 1);
    if (!mounted) return;
    if (ok) {
      NotificationService.cartCountNotifier.value++;
      _message('${product.nama} ditambahkan ke keranjang.');
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
    final provider = context.watch<ProductProvider>();
    final products = provider.products;
    final categories = <String>{'Semua', ...products.map((p) => p.kategori).where((e) => e.trim().isNotEmpty)}.toList();
    final visible = products.where((p) => (_category == 'Semua' || p.kategori == _category) &&
      (_search.text.isEmpty || p.nama.toLowerCase().contains(_search.text.toLowerCase()))).toList();
    final featured = visible.where((p) => p.tersedia && p.stok > 0).take(6).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: provider.refresh,
        color: colors.primary,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.eco_rounded, color: Colors.white, size: 25)),
                const SizedBox(width: 11),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('TANIMART', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: colors.primary, fontSize: 17)),
                  Text('Pasar segar, langsung di genggaman', style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                ])),
                IconButton.filledTonal(onPressed: widget.onGoToCart, icon: const Icon(Icons.shopping_bag_outlined), tooltip: 'Keranjang'),
              ]),
              const SizedBox(height: 22),
              Text('Belanja lebih segar,', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1)),
              Text('hidup lebih baik.', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colors.primary, height: 1.2)),
              const SizedBox(height: 7),
              Text('Temukan kebutuhan pertanian dan harian pilihan.', style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
              const SizedBox(height: 18),
              TextField(controller: _search, onChanged: (_) => setState(() {}), onSubmitted: (_) => widget.onGoToProducts?.call(),
                decoration: InputDecoration(hintText: 'Cari sayur, buah, sembako...', prefixIcon: const Icon(Icons.search_rounded), suffixIcon: _search.text.isEmpty ? null : IconButton(onPressed: () { _search.clear(); setState(() {}); }, icon: const Icon(Icons.close)), filled: true, fillColor: colors.surface, contentPadding: const EdgeInsets.symmetric(vertical: 15), border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: colors.outlineVariant)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: BorderSide(color: colors.outlineVariant)))),
              const SizedBox(height: 18),
              Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, Color.lerp(colors.primary, const Color(0xFF9BCB64), .42)!], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(22)),
                child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(20)), child: const Text('PILIHAN HARI INI', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1))),
                  const SizedBox(height: 12), const Text('Dari kebun\nuntuk keluarga.', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.15)),
                  const SizedBox(height: 8), const Text('Belanja kebutuhan segar dengan mudah.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 14), TextButton(onPressed: widget.onGoToProducts, style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: colors.primary, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9)), child: const Text('Jelajahi produk  →', style: TextStyle(fontWeight: FontWeight.w800))),
                ])), const SizedBox(width: 5), const Icon(Icons.spa_rounded, color: Colors.white, size: 88)])),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Kategori', 'Pilih kebutuhanmu'),
              const SizedBox(height: 12),
              SizedBox(height: 42, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (_, _) => const SizedBox(width: 8), itemBuilder: (_, i) {
                final value = categories[i]; final selected = _category == value;
                return ChoiceChip(label: Text(value), selected: selected, onSelected: (_) => setState(() => _category = value), showCheckmark: false, labelStyle: TextStyle(fontWeight: FontWeight.w700, color: selected ? colors.onPrimary : colors.onSurfaceVariant), selectedColor: colors.primary, backgroundColor: colors.surface, side: BorderSide(color: selected ? colors.primary : colors.outlineVariant));
              })),
              const SizedBox(height: 24),
              _sectionTitle(context, _category == 'Semua' ? 'Rekomendasi untukmu' : _category, 'Produk pilihan dari TaniMart', action: 'Lihat semua', onAction: widget.onGoToProducts),
              const SizedBox(height: 13),
            ]),
          )),
          if (provider.isLoading && products.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: CircularProgressIndicator()))
          else if (provider.errorMessage != null && products.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _stateMessage(context, Icons.wifi_off_rounded, 'Belum dapat memuat produk', provider.errorMessage!, 'Coba lagi', provider.refresh))
          else if (featured.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _stateMessage(context, Icons.inventory_2_outlined, 'Produk belum tersedia', 'Coba kategori atau kata kunci lain.', 'Tampilkan semua', () => setState(() { _category = 'Semua'; _search.clear(); })))
          else SliverPadding(padding: const EdgeInsets.fromLTRB(20, 0, 20, 28), sliver: SliverGrid(delegate: SliverChildBuilderDelegate((context, index) => _FreshProductCard(product: featured[index], onTap: () => _open(featured[index]), onAdd: () => _add(featured[index])), childCount: featured.length), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 13, crossAxisSpacing: 13, childAspectRatio: .68))),
          if (provider.isLoading && products.isNotEmpty) const SliverToBoxAdapter(child: LinearProgressIndicator(minHeight: 2)),
        ]),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String subtitle, {String? action, VoidCallback? onAction}) => Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 2), Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))])), if (action != null) TextButton(onPressed: onAction, child: Text(action))]);

  Widget _stateMessage(BuildContext context, IconData icon, String title, String detail, String button, VoidCallback onTap) => Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 42, color: Theme.of(context).colorScheme.primary), const SizedBox(height: 12), Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(detail, textAlign: TextAlign.center), const SizedBox(height: 14), FilledButton(onPressed: onTap, child: Text(button))])));
}

class _FreshProductCard extends StatelessWidget {
  final Product product; final VoidCallback onTap; final VoidCallback onAdd;
  const _FreshProductCard({required this.product, required this.onTap, required this.onAdd});
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Material(color: c.surface, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: c.outlineVariant.withValues(alpha: .7))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child: Stack(children: [Positioned.fill(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(17)), child: ProductImage(imageUrl: product.foto, productName: product.nama, category: product.kategori, fit: BoxFit.cover))), Positioned(left: 9, top: 9, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: c.surface.withValues(alpha: .94), borderRadius: BorderRadius.circular(30)), child: Text(product.kategori, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: c.onSurface))))])),
      Padding(padding: const EdgeInsets.fromLTRB(11, 10, 11, 11), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(product.nama, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)), const SizedBox(height: 4), Text('Rp ${_rupiah(product.harga)}', style: TextStyle(color: c.primary, fontWeight: FontWeight.w900, fontSize: 14)), const SizedBox(height: 2), Text('per ${product.satuanJual} • Stok ${product.stok}', style: TextStyle(color: c.onSurfaceVariant, fontSize: 10)), const SizedBox(height: 8), SizedBox(width: double.infinity, height: 34, child: FilledButton.tonal(onPressed: product.tersedia && product.stok > 0 ? onAdd : null, style: FilledButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('＋ Keranjang', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800))))]))
    ]))));
  }
  String _rupiah(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
