import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../constants/product_images.dart';

/// Widget gambar produk terpadu Tani Mart.
/// Mendukung foto lokal (assets/images/products/) dan foto remote dari Laravel API.
/// Dilengkapi sistem fallback dan placeholder bertema pertanian yang anggun tanpa layout shift.
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

    final hasValidRemoteUrl = imageUrl != null &&
        imageUrl!.trim().isNotEmpty &&
        (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'));

    if (hasValidRemoteUrl) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholderShimmer(context),
        errorWidget: (context, url, error) => _buildLocalOrPlaceholder(context),
      );
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
    final theme = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.mutedContainer,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.primaryGreen,
          ),
        ),
      ),
    );
  }

  Widget _buildAgriculturalPlaceholder(BuildContext context) {
    final theme = AppColors.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.lightGreen,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryGreen.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco_rounded,
                color: theme.primaryGreen,
                size: 28,
              ),
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
                    color: theme.primaryGreen,
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
