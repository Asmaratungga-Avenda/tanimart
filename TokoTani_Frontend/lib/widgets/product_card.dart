import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/formatters.dart';
import '../models/product.dart';
import 'product_image.dart';

/// Kartu produk ringkas: foto, nama, harga, satuan/stok, dan tombol tambah.
/// Detail lengkap ada di halaman Detail Produk.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAdd,
    this.adding = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool adding;

  static const double _imageAspect = 1.1;
  static const double _contentHeight = 104;

  /// Tinggi kartu untuk lebar tertentu; ikut skala teks agar tidak overflow.
  static double extentFor(double width, double textScale) =>
      width / _imageAspect + _contentHeight * textScale;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final available = product.isAvailable;
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final screenWidth = MediaQuery.of(context).size.width;

    final stockLabel = !available
        ? 'Stok habis'
        : '/${product.satuanJual} · Stok ${product.stok}';

    // Ukuran gambar responsif: menyesuaikan dengan lebar layar
    final imageCacheWidth = (screenWidth * 0.45).round().clamp(240, 720);

    return Material(
      color: p.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: _imageAspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(
                    url: product.foto,
                    cacheWidth: imageCacheWidth,
                  ),
                  if (!available)
                    ColoredBox(color: p.background.withValues(alpha: 0.6)),
                  if (!available)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.neutralSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Stok habis',
                          style: text.labelSmall?.copyWith(
                            color: p.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nama,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontSize: (14 * scale).clamp(12, 18),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                formatRupiah(product.harga),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall?.copyWith(
                                  color: p.brandText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: (14 * scale).clamp(12, 18),
                                ),
                              ),
                              Text(
                                stockLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.labelSmall?.copyWith(
                                  color: p.textSecondary,
                                  fontSize: (11 * scale).clamp(10, 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        _AddButton(
                          enabled: available,
                          loading: adding,
                          onTap: onAdd,
                        ),
                      ],
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

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active = enabled && !loading;
    return Semantics(
      button: true,
      label: 'Tambah ke keranjang',
      child: Material(
        color: enabled ? p.brand : p.neutralSoft,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: active ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: p.onBrand,
                      ),
                    )
                  : Icon(
                      Icons.add_rounded,
                      size: 20,
                      color: enabled ? p.onBrand : p.textSecondary,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grid dua kolom (tiga di layar lebar) dengan tinggi kartu pasti.
class SliverProductGrid extends StatelessWidget {
  const SliverProductGrid({
    super.key,
    required this.products,
    required this.onOpen,
    required this.onAdd,
    required this.isAdding,
  });

  final List<Product> products;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onAdd;
  final bool Function(int productId) isAdding;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width >= 520 ? 3 : 2;
        final cardWidth = (width - _gap * (columns - 1)) / columns;
        final scale = MediaQuery.textScalerOf(context).scale(1);

        return SliverGrid(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: _gap,
            crossAxisSpacing: _gap,
            mainAxisExtent: ProductCard.extentFor(cardWidth, scale),
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final product = products[index];
            return ProductCard(
              key: ValueKey<int>(product.id),
              product: product,
              adding: isAdding(product.id),
              onTap: () => onOpen(product),
              onAdd: () => onAdd(product),
            );
          }, childCount: products.length),
        );
      },
    );
  }
}
