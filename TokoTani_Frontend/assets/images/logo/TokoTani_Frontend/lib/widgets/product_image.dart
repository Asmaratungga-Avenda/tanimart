import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/theme/app_palette.dart';

/// Foto produk dari server. Bila foto kosong atau gagal dimuat, tampil
/// placeholder netral (bukan foto produk lain). Mengisi ruang yang diberikan induknya.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.cacheWidth = 480,
    this.iconSize = 32,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int cacheWidth;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(url);
    final Widget image = resolved == null
        ? _Placeholder(iconSize: iconSize)
        : CachedNetworkImage(
            imageUrl: resolved,
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: cacheWidth,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, _) =>
                ColoredBox(color: context.colors.surfaceContainerHighest),
            errorWidget: (context, _, _) => _Placeholder(iconSize: iconSize),
          );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.brandSoft,
      child: Center(
        child: Icon(Icons.eco_outlined, size: iconSize, color: p.brandText),
      ),
    );
  }
}
