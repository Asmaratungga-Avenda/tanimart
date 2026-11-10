import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_palette.dart';

/// Tema terpusat TaniMart: Light dan Dark dibangun dari satu fungsi sehingga
/// komponen selalu konsisten. Mode Sistem ditangani oleh `ThemeMode.system`.
class AppTheme {
  const AppTheme._();

  static const String fontFamily = 'Poppins';

  static final ThemeData light = _build(Brightness.light, AppPalette.light);
  static final ThemeData dark = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: p.brand,
      onPrimary: p.onBrand,
      primaryContainer: p.brandSoft,
      onPrimaryContainer: p.brandText,
      secondary: BrandColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer: p.brandSoft,
      onSecondaryContainer: p.brandText,
      tertiary: p.warning,
      onTertiary: isDark ? Colors.black : Colors.white,
      tertiaryContainer: p.warningSoft,
      onTertiaryContainer: p.warning,
      error: p.danger,
      onError: isDark ? const Color(0xFF1B1B1B) : Colors.white,
      errorContainer: p.dangerSoft,
      onErrorContainer: p.danger,
      surface: p.surface,
      onSurface: p.textPrimary,
      onSurfaceVariant: p.textSecondary,
      outline: isDark ? const Color(0xFF5A5A5A) : const Color(0xFFC9CFC6),
      outlineVariant: p.border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1B2420),
      onInverseSurface: isDark ? const Color(0xFF121212) : const Color(0xFFF7F8F6),
      inversePrimary: p.brandText,
      surfaceTint: Colors.transparent,
      surfaceContainerLowest: p.background,
      surfaceContainerLow: p.surface,
      surfaceContainer: p.card,
      surfaceContainerHigh: p.card,
      surfaceContainerHighest:
          isDark ? const Color(0xFF303030) : const Color(0xFFEEF1EC),
    );

    final base = ThemeData(
      brightness: brightness,
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      extensions: <ThemeExtension<dynamic>>[p],
    );

    final textTheme = base.textTheme
        .apply(bodyColor: p.textPrimary, displayColor: p.textPrimary)
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.3,
          ),
          titleMedium: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          titleSmall: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          bodyLarge: const TextStyle(fontSize: 14, height: 1.45),
          bodyMedium: const TextStyle(fontSize: 13, height: 1.45),
          bodySmall: const TextStyle(fontSize: 12, height: 1.4),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        )
        .apply(fontFamily: fontFamily);

    // Style teks di atas kehilangan warna saat copyWith; terapkan ulang.
    final colored = textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return base.copyWith(
      textTheme: colored,
      primaryTextTheme: colored,
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        titleTextStyle: colored.titleLarge?.copyWith(color: p.textPrimary),
        iconTheme: IconThemeData(color: p.textPrimary),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.surface,
                systemNavigationBarIconBrightness: Brightness.light,
              )
            : SystemUiOverlayStyle.dark.copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: p.surface,
                systemNavigationBarIconBrightness: Brightness.dark,
              ),
      ),
      iconTheme: IconThemeData(color: p.textPrimary),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: p.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: colored.bodyMedium?.copyWith(color: p.textSecondary),
        labelStyle: colored.bodyMedium?.copyWith(color: p.textSecondary),
        floatingLabelStyle: colored.bodySmall?.copyWith(color: p.brandText),
        helperStyle: colored.bodySmall?.copyWith(color: p.textSecondary),
        errorStyle: colored.bodySmall?.copyWith(color: p.danger),
        prefixIconColor: p.textSecondary,
        suffixIconColor: p.textSecondary,
        border: inputBorder(p.border),
        enabledBorder: inputBorder(p.border),
        disabledBorder: inputBorder(p.border),
        focusedBorder: inputBorder(p.brand, 1.5),
        errorBorder: inputBorder(p.danger),
        focusedErrorBorder: inputBorder(p.danger, 1.5),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: p.onBrand,
          disabledBackgroundColor: p.neutralSoft,
          disabledForegroundColor: p.textSecondary,
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          textStyle: colored.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.brandText,
          disabledForegroundColor: p.textSecondary,
          minimumSize: const Size(0, 48),
          side: BorderSide(color: p.brand),
          shape: buttonShape,
          textStyle: colored.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brandText,
          disabledForegroundColor: p.textSecondary,
          textStyle: colored.labelLarge,
          shape: buttonShape,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.textPrimary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.brand,
        disabledColor: p.neutralSoft,
        side: BorderSide(color: p.border),
        labelStyle: colored.labelMedium?.copyWith(color: p.textPrimary),
        secondaryLabelStyle: colored.labelMedium?.copyWith(color: p.onBrand),
        checkmarkColor: p.onBrand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: colored.titleMedium?.copyWith(color: p.textPrimary),
        contentTextStyle: colored.bodyMedium?.copyWith(color: p.textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: p.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.card,
        surfaceTintColor: Colors.transparent,
        textStyle: colored.bodyMedium?.copyWith(color: p.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: colored.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        actionTextColor: isDark ? p.brand : p.brandSoft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brandText,
        circularTrackColor: p.neutralSoft,
        linearTrackColor: p.neutralSoft,
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: p.brand,
        headerForegroundColor: p.onBrand,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.brandText,
        selectionColor: p.brand.withValues(alpha: 0.3),
        selectionHandleColor: p.brandText,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
