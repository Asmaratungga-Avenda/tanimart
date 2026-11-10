import 'package:flutter/material.dart';

import '../utils/order_status.dart';

/// Warna merek TaniMart (sama pada Light dan Dark).
class BrandColors {
  const BrandColors._();

  static const Color primary = Color(0xFF27843D);
  static const Color secondary = Color(0xFF39A84A);
  static const Color light = Color(0xFFE8F7E9);
  static const Color deep = Color(0xFF1B5E2D);
}

/// Seluruh warna semantik aplikasi. Widget tidak boleh memakai warna literal;
/// ambil dari `context.palette` agar Light/Dark selalu konsisten.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color brand;
  final Color onBrand;
  final Color brandText;
  final Color brandSoft;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color info;
  final Color infoSoft;
  final Color danger;
  final Color dangerSoft;
  final Color neutral;
  final Color neutralSoft;
  final Color shadow;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.brand,
    required this.onBrand,
    required this.brandText,
    required this.brandSoft,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.info,
    required this.infoSoft,
    required this.danger,
    required this.dangerSoft,
    required this.neutral,
    required this.neutralSoft,
    required this.shadow,
  });

  static const AppPalette light = AppPalette(
    background: Color(0xFFF7F8F6),
    surface: Color(0xFFFFFFFF),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE4E8E1),
    textPrimary: Color(0xFF1B2420),
    textSecondary: Color(0xFF5F6B63),
    brand: BrandColors.primary,
    onBrand: Color(0xFFFFFFFF),
    brandText: Color(0xFF1F6E32),
    brandSoft: BrandColors.light,
    success: Color(0xFF1F6E32),
    successSoft: BrandColors.light,
    warning: Color(0xFF9A5B00),
    warningSoft: Color(0xFFFFF4DB),
    info: Color(0xFF1D5FA8),
    infoSoft: Color(0xFFE6F0FB),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFDECEA),
    neutral: Color(0xFF4B5563),
    neutralSoft: Color(0xFFEEF0EC),
    shadow: Color(0x14000000),
  );

  static const AppPalette dark = AppPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    card: Color(0xFF252525),
    border: Color(0xFF383838),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFB0B0B0),
    brand: BrandColors.primary,
    onBrand: Color(0xFFFFFFFF),
    brandText: Color(0xFF5BC46D),
    brandSoft: Color(0xFF1E3A25),
    success: Color(0xFF5BC46D),
    successSoft: Color(0xFF1E3A25),
    warning: Color(0xFFF2B440),
    warningSoft: Color(0xFF3A2E12),
    info: Color(0xFF6FB1F2),
    infoSoft: Color(0xFF14283D),
    danger: Color(0xFFF2726B),
    dangerSoft: Color(0xFF3D1B19),
    neutral: Color(0xFFB0B0B0),
    neutralSoft: Color(0xFF303030),
    shadow: Color(0x66000000),
  );

  /// Pasangan (latar, teks) untuk lencana status.
  (Color, Color) tonePair(StatusTone tone) {
    switch (tone) {
      case StatusTone.success:
        return (successSoft, success);
      case StatusTone.warning:
        return (warningSoft, warning);
      case StatusTone.info:
        return (infoSoft, info);
      case StatusTone.danger:
        return (dangerSoft, danger);
      case StatusTone.neutral:
        return (neutralSoft, neutral);
    }
  }

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? brand,
    Color? onBrand,
    Color? brandText,
    Color? brandSoft,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? info,
    Color? infoSoft,
    Color? danger,
    Color? dangerSoft,
    Color? neutral,
    Color? neutralSoft,
    Color? shadow,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      brandText: brandText ?? this.brandText,
      brandSoft: brandSoft ?? this.brandSoft,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      neutral: neutral ?? this.neutral,
      neutralSoft: neutralSoft ?? this.neutralSoft,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return AppPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      brand: l(brand, other.brand),
      onBrand: l(onBrand, other.onBrand),
      brandText: l(brandText, other.brandText),
      brandSoft: l(brandSoft, other.brandSoft),
      success: l(success, other.success),
      successSoft: l(successSoft, other.successSoft),
      warning: l(warning, other.warning),
      warningSoft: l(warningSoft, other.warningSoft),
      info: l(info, other.info),
      infoSoft: l(infoSoft, other.infoSoft),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      neutral: l(neutral, other.neutral),
      neutralSoft: l(neutralSoft, other.neutralSoft),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
