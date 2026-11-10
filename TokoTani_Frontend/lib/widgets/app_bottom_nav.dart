import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

/// Navigasi bawah lima item. Keranjang berada di tengah sebagai tombol bulat
/// menonjol dengan lencana jumlah, mengikuti desain Figma.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.cartCount,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final int cartCount;

  static const double _barHeight = 62;
  static const double _bump = 18;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    Widget item(int index, IconData icon, IconData activeIcon, String label) {
      final selected = currentIndex == index;
      final color = selected ? p.brandText : p.textSecondary;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            onTap: () => onSelected(index),
            child: SizedBox(
              height: _barHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? activeIcon : icon, size: 24, color: color),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final cartSelected = currentIndex == 2;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight + _bump,
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: _barHeight,
                child: Row(
                  children: [
                    item(0, Icons.home_outlined, Icons.home_rounded, 'Beranda'),
                    item(
                      1,
                      Icons.storefront_outlined,
                      Icons.storefront_rounded,
                      'Produk',
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'Keranjang',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              color: cartSelected
                                  ? p.brandText
                                  : p.textSecondary,
                              fontWeight: cartSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    item(
                      3,
                      Icons.receipt_long_outlined,
                      Icons.receipt_long_rounded,
                      'Pesanan',
                    ),
                    item(
                      4,
                      Icons.person_outline_rounded,
                      Icons.person_rounded,
                      'Akun',
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _CartButton(
                    count: cartCount,
                    selected: cartSelected,
                    onTap: () => onSelected(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: count > 0 ? 'Keranjang, $count produk' : 'Keranjang',
      child: SizedBox(
        width: 64,
        height: 56,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Material(
              color: p.brand,
              shape: CircleBorder(side: BorderSide(color: p.surface, width: 3)),
              elevation: 3,
              shadowColor: p.shadow,
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: SizedBox(
                  width: 54,
                  height: 54,
                  child: Icon(
                    Icons.shopping_bag_rounded,
                    color: p.onBrand,
                    size: 26,
                  ),
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: 0,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  decoration: BoxDecoration(
                    color: scheme.error,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: p.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      color: scheme.onError,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
