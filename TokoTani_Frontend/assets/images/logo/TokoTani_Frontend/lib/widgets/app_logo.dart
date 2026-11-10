import 'package:flutter/material.dart';

import '../core/theme/app_palette.dart';

/// Lokasi berkas logo. Letakkan gambar di folder `assets/images/logo/`.
class LogoAssets {
  const LogoAssets._();

  /// Logo lengkap (emblem + tulisan). Dipakai di Splash dan Login.
  static const String full = 'assets/images/logo/tanimart_logo.png';

  /// Ikon persegi (emblem saja). Dipakai di header Beranda.
  static const String icon = 'assets/images/logo/tanimart_icon.png';
}

/// Logo TaniMart. Memakai berkas gambar bila ada; bila belum ada, otomatis
/// memakai logo gambar-tema (ikon daun + tulisan) sehingga aplikasi tidak error.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 36, this.showWordmark = true, this.full = false});

  /// Tinggi logo.
  final double size;
  final bool showWordmark;

  /// true: pakai logo lengkap (Splash/Login). false: ikon kecil (header).
  final bool full;

  @override
  Widget build(BuildContext context) {
    if (full) {
      return Image.asset(
        LogoAssets.full,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, _, _) => _Drawn(size: size * 0.45, wordmark: true),
      );
    }
    final mark = Image.asset(
      LogoAssets.icon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, _, _) => _Drawn(size: size, wordmark: false),
    );
    if (!showWordmark) return mark;
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 8),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Tani', style: TextStyle(color: p.textPrimary)),
              TextSpan(text: 'Mart', style: TextStyle(color: p.brandText)),
            ],
          ),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _Drawn extends StatelessWidget {
  const _Drawn({required this.size, required this.wordmark});

  final double size;
  final bool wordmark;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.brand,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.eco_rounded, color: p.onBrand, size: size * 0.6),
    );
    if (!wordmark) return mark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Tani', style: TextStyle(color: p.textPrimary)),
              TextSpan(text: 'Mart', style: TextStyle(color: p.brandText)),
            ],
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: size * 0.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
