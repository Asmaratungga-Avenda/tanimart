import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/product_images.dart';

/// Widget gambar produk terpadu AgriMart.
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
        placeholder: (context, url) => _buildPlaceholderShimmer(),
        errorWidget: (context, url, error) => _buildLocalOrPlaceholder(),
      );
    } else {
      imageWidget = _buildLocalOrPlaceholder();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildLocalOrPlaceholder() {
    final assetPath = fallbackAsset ??
        ProductImages.getProductAsset(productName, category: category);

    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return _buildAgriculturalPlaceholder();
      },
    );
  }

  Widget _buildPlaceholderShimmer() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF1F5F0),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }

  Widget _buildAgriculturalPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFE8F5E9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFF2E7D32),
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
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
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
