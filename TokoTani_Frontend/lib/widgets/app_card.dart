import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

/// Kartu standar: latar, border, dan radius dari tema.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.onTap,
    this.color,
    this.radius = 14,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: color ?? p.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: p.border),
      ),
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    return margin == null ? card : Padding(padding: margin!, child: card);
  }
}
