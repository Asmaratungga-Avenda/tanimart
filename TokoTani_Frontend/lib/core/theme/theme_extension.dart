import 'package:flutter/material.dart';

/// Helper statis untuk akses warna tema dari BuildContext.
/// Contoh penggunaan: AppColors.of(context).primaryGreen
class AppColors {
  final BuildContext context;
  const AppColors(this.context);

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  ColorScheme get scheme => Theme.of(context).colorScheme;

  Color get primaryGreen => scheme.primary;
  Color get onPrimary => scheme.onPrimary;
  Color get onError => scheme.onError;
  Color get surfaceColor => scheme.surface;
  Color get backgroundColor => Theme.of(context).scaffoldBackgroundColor;
  Color get textPrimary => scheme.onSurface;
  Color get textSecondary => scheme.onSurfaceVariant;
  Color get accentOrange => scheme.tertiary;
  Color get warning => scheme.tertiary;
  Color get warningContainer => scheme.tertiaryContainer;
  Color get info => scheme.secondary;
  Color get errorRed => scheme.error;
  Color get errorContainer => scheme.errorContainer;
  Color get lightGreen => scheme.secondaryContainer;
  Color get mutedContainer => scheme.surfaceContainerHighest;
  Color get borderColor => scheme.outlineVariant;
  Color get imageOverlay => Colors.black.withValues(alpha: 0.5);
  Color get imageOverlayStrong => Colors.black.withValues(alpha: 0.65);
  Color get onImage => Colors.white;
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.35) : Colors.black.withValues(alpha: 0.06);

  List<BoxShadow> get softShadow => isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

  static AppColors of(BuildContext context) => AppColors(context);
}
