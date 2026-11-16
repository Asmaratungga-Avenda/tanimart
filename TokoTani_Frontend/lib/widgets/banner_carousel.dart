import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../core/config/api_config.dart';
import '../core/theme/app_palette.dart';
import '../services/api_service.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const _autoPlayInterval = Duration(seconds: 5);
  static const _pageDuration = Duration(milliseconds: 450);

  final PageController _pageController = PageController();
  List<Map<String, dynamic>> _banners = const [];
  Timer? _autoPlayTimer;
  String? _errorMessage;
  int _currentPage = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final banners = await ApiService.getBanners();
      if (!mounted) return;

      final validBanners = banners
          .where((banner) {
            final image = banner['url'] ?? banner['gambar'];
            return image is String && image.trim().isNotEmpty;
          })
          .toList(growable: false);

      setState(() {
        _banners = validBanners;
        _currentPage = 0;
        _isLoading = false;
        if (banners.isNotEmpty && validBanners.isEmpty) {
          _errorMessage = 'Banner tidak memiliki alamat gambar yang valid.';
        } else if (banners.isEmpty) {
          _errorMessage = 'Belum ada banner yang tersedia.';
        }
      });
      _startAutoPlay();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      debugPrint('Unable to load banners: $error');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Banner belum dapat dimuat. Silakan coba lagi.';
      });
    }
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (_banners.length < 2) return;

    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: _pageDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  String? _imageUrl(Map<String, dynamic> banner) {
    return ApiConfig.resolveMedia(
      (banner['url'] ?? banner['gambar'])?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    if (_isLoading) {
      return const _BannerMessage(
        icon: Icons.photo_outlined,
        message: 'Memuat banner...',
      );
    }
    if (_banners.isEmpty) {
      return _BannerMessage(
        icon: Icons.image_not_supported_outlined,
        message: _errorMessage ?? 'Belum ada banner yang tersedia.',
        onRetry: _loadBanners,
      );
    }

    return Column(
      children: [
        Material(
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: AspectRatio(
              aspectRatio: 2,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _banners.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) {
                  final banner = _banners[index];
                  final imageUrl = _imageUrl(banner);
                  if (imageUrl == null) {
                    return const _BannerMessage(
                      icon: Icons.broken_image_outlined,
                      message: 'Gambar banner tidak tersedia.',
                    );
                  }
                  return CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => ColoredBox(
                      color: palette.neutralSoft,
                      child: Center(
                        child: Icon(
                          Icons.photo_outlined,
                          color: palette.textSecondary,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) {
                      debugPrint('Unable to load banner image $url: $error');
                      return const _BannerMessage(
                        icon: Icons.broken_image_outlined,
                        message: 'Gambar banner gagal dimuat.',
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        if (_banners.length > 1) ...[
          const SizedBox(height: 10),
          Semantics(
            label: 'Banner ${_currentPage + 1} dari ${_banners.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_banners.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: index == _currentPage ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? palette.brand
                        : palette.border,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerMessage extends StatelessWidget {
  const _BannerMessage({
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: palette.neutralSoft,
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 2,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: palette.textSecondary),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
                ),
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Coba lagi'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
