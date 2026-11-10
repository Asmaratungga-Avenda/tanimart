import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/theme/app_palette.dart';

/// Foto produk dari backend Laravel. Hanya memuat gambar jaringan —
/// tidak ada fallback ikon atau placeholder gambar. Bila URL kosong
/// atau gagal muat, area kosong (tidak ada gambar) ditampilkan.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.cacheWidth = 480,
    this.height,
    this.width,
  });

  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final int cacheWidth;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMedia(url);

    if (resolved == null || resolved.isEmpty) {
      return _empty(context);
    }

    final widget = CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => _skeleton(context),
      errorWidget: (context, _, _) => _empty(context),
    );

    if (borderRadius == null) return widget;
    return ClipRRect(borderRadius: borderRadius!, child: widget);
  }

  Widget _skeleton(BuildContext context) {
    final p = context.palette;
    return ColoredBox(color: p.neutralSoft);
  }

  Widget _empty(BuildContext context) {
    final p = context.palette;
    return ColoredBox(color: p.neutralSoft);
  }
}
