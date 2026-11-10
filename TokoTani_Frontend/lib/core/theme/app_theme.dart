import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

/// TaniMart Fresh Design System — clean market surfaces and botanical green.
class AppTheme {
  static const Color lightPrimaryGreen = Color(0xFF27843D);
  static const Color lightSecondaryGreen = Color(0xFF39A84A);
  static const Color lightLightGreen = Color(0xFFE8F7E9);
  static const Color lightBackground = Color(0xFFF7F8F6);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF17251B);
  static const Color lightTextSecondary = Color(0xFF68766C);
  static const Color lightAccentOrange = Color(0xFFE99A35);
  static const Color lightErrorRed = Color(0xFFCE4545);
  static const Color lightBorderColor = Color(0xFFE5EBE5);

  static const Color darkPrimaryGreen = Color(0xFF78C887);
  static const Color darkSecondaryGreen = Color(0xFF4EAD65);
  static const Color darkLightGreen = Color(0xFF243D2A);
  static const Color darkBackground = Color(0xFF121812);
  static const Color darkSurface = Color(0xFF1C241E);
  static const Color darkTextPrimary = Color(0xFFF1F5F1);
  static const Color darkTextSecondary = Color(0xFFADB9AE);
  static const Color darkAccentOrange = Color(0xFFF2B45E);
  static const Color darkErrorRed = Color(0xFFFF7777);
  static const Color darkBorderColor = Color(0xFF344037);

  static List<BoxShadow> get softShadow => [BoxShadow(color: Colors.black.withValues(alpha: .045), blurRadius: 18, offset: const Offset(0, 7))];
  static List<BoxShadow> get softShadowDark => [BoxShadow(color: Colors.black.withValues(alpha: .25), blurRadius: 18, offset: const Offset(0, 7))];

  static ThemeData _build({required bool dark}) {
    final primary = dark ? darkPrimaryGreen : lightPrimaryGreen;
    final secondary = dark ? darkSecondaryGreen : lightSecondaryGreen;
    final surface = dark ? darkSurface : lightSurface;
    final background = dark ? darkBackground : lightBackground;
    final text = dark ? darkTextPrimary : lightTextPrimary;
    final muted = dark ? darkTextSecondary : lightTextSecondary;
    final border = dark ? darkBorderColor : lightBorderColor;
    final error = dark ? darkErrorRed : lightErrorRed;
    final scheme = ColorScheme.fromSeed(seedColor: primary, brightness: dark ? Brightness.dark : Brightness.light, primary: primary, secondary: secondary, surface: surface, error: error);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, scaffoldBackgroundColor: background, visualDensity: VisualDensity.standard);
    final radius = BorderRadius.circular(16);
    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(bodyColor: text, displayColor: text),
      appBarTheme: AppBarTheme(backgroundColor: background, foregroundColor: text, elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: GoogleFonts.inter(color: text, fontSize: 19, fontWeight: FontWeight.w800), systemOverlayStyle: SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: dark ? Brightness.light : Brightness.dark)),
      cardTheme: CardThemeData(color: surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: radius, side: BorderSide(color: border))),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: surface, hintStyle: TextStyle(color: muted), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: border)), enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: border)), focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: primary, width: 1.5))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: primary, foregroundColor: dark ? const Color(0xFF102015) : Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13), textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: primary, side: BorderSide(color: primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)))),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    );
  }

  static ThemeData get lightTheme => _build(dark: false);
  static ThemeData get darkTheme => _build(dark: true);
  static Color getSurfaceColor(bool dark) => dark ? darkSurface : lightSurface;
  static Color getBackgroundColor(bool dark) => dark ? darkBackground : lightBackground;
  static Color getTextPrimaryColor(bool dark) => dark ? darkTextPrimary : lightTextPrimary;
  static Color getTextSecondaryColor(bool dark) => dark ? darkTextSecondary : lightTextSecondary;
  static Color getBorderColor(bool dark) => dark ? darkBorderColor : lightBorderColor;
  static Color getPrimaryGreen(bool dark) => dark ? darkPrimaryGreen : lightPrimaryGreen;
  static Color getSecondaryGreen(bool dark) => dark ? darkSecondaryGreen : lightSecondaryGreen;
  static Color getLightGreen(bool dark) => dark ? darkLightGreen : lightLightGreen;
  static Color getAccentOrange(bool dark) => dark ? darkAccentOrange : lightAccentOrange;
  static Color getErrorRed(bool dark) => dark ? darkErrorRed : lightErrorRed;
  static List<BoxShadow> getSoftShadow(bool dark) => dark ? softShadowDark : softShadow;
}
