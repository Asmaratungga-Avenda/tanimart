import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../constants/product_images.dart';
import '../config/api_config.dart';

/// Widget gambar produk terpadu Tani Mart.
/// Mendukung foto lokal (assets/images/products/) dan foto remote dari Laravel API.
class ProductImage extends StatelessWidget {
  final String? imageUrl;
  final String? fallbackAsset;
  final String? productName;
  final String? category;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImage({
    super.key,
    this.imageUrl,
    this.fallbackAsset,
    this.productName,
    this.category,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    final resolvedUrl = _resolveImageUrl(imageUrl);
    final hasValidRemoteUrl = resolvedUrl != null;

    if (hasValidRemoteUrl) {
      if (kIsWeb) {
        // Flutter Web sering bermasalah dengan CORS/CanvasKit pada Image.network/CachedNetworkImage
        // Gunakan Image.network standar dengan penanganan error yang baik untuk Web
        imageWidget = Image.network(
          resolvedUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholderShimmer(context);
          },
          errorBuilder: (context, error, stackTrace) {
            debugPrint('ProductImage Web Error: $error URL: $resolvedUrl');
            return _buildLocalOrPlaceholder(context);
          },
        );
      } else {
        imageWidget = CachedNetworkImage(
          imageUrl: resolvedUrl,
          width: width,
          height: height,
          fit: fit,
          placeholder: (context, url) => _buildPlaceholderShimmer(context),
          errorWidget: (context, url, error) => _buildLocalOrPlaceholder(context),
        );
      }
    } else {
      imageWidget = _buildLocalOrPlaceholder(context);
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  String? _resolveImageUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') return null;

    final apiUri = Uri.tryParse(ApiConfig.baseUrl);
    if (apiUri == null || apiUri.host.isEmpty) return null;

    // Menentukan origin (scheme + host + port) dari API untuk digunakan sebagai dasar
    final origin = '${apiUri.scheme}://${apiUri.authority}';

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      // Jika sudah berupa URL lengkap, pastikan host localhost diganti ke IP yang sesuai platform
      final localHost = ['localhost', '127.0.0.1', '0.0.0.0'].contains(parsed.host);
      if (localHost) {
        return parsed
            .replace(
              scheme: apiUri.scheme,
              host: apiUri.host,
              port: apiUri.hasPort ? apiUri.port : null,
            )
            .toString();
      }
      return value;
    }

    // Jika berupa path relatif (misal: products/image.jpg atau /storage/products/image.jpg)
    var path = value.replaceAll('\\', '/');

    // Pastikan path memiliki prefix /storage/ jika itu adalah path dari Filament
    if (!path.startsWith('/')) {
      if (path.startsWith('products/') ||
          path.startsWith('categories/') ||
          path.startsWith('banners/')) {
        path = '/storage/$path';
      } else if (!path.startsWith('storage/')) {
        path = '/storage/$path';
      } else {
        path = '/$path';
      }
    } else if (path.startsWith('/products/') ||
        path.startsWith('/categories/') ||
        path.startsWith('/banners/')) {
      path = '/storage$path';
    }

    // Hilangkan double slash jika ada
    final cleanPath = path.replaceAll('//', '/');
    return '$origin$cleanPath';
  }

  Widget _buildLocalOrPlaceholder(BuildContext context) {
    final assetPath = fallbackAsset ??
        ProductImages.getProductAsset(productName, category: category);

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildAgriculturalPlaceholder(context);
      },
    );
  }

  Widget _buildPlaceholderShimmer(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildAgriculturalPlaceholder(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: colors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_rounded,
              color: colors.primary.withValues(alpha: 0.4),
              size: 28,
            ),
            if (productName != null && productName!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  productName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
