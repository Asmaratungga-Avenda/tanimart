import 'package:flutter/material.dart';

/// Widget pembungkus responsif yang membatasi lebar konten pada layar lebar (desktop/tablet)
/// dan membiarkan konten mengambil lebar penuh pada layar kecil (mobile).
///
/// Breakpoint:
/// - Mobile: lebar < 600px → konten penuh
/// - Tablet: 600px–900px → maks 560px, tersentrasi
/// - Desktop: > 900px → maks 640px, tersentrasi
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double mobileBreakpoint;
  final double tabletMaxWidth;
  final double desktopMaxWidth;
  final EdgeInsetsGeometry? padding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.mobileBreakpoint = 600,
    this.tabletMaxWidth = 560,
    this.desktopMaxWidth = 640,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;

        // Mobile: konten penuh tanpa batasan
        if (screenWidth < mobileBreakpoint) {
          return padding != null
              ? Padding(padding: padding!, child: child)
              : child;
        }

        // Tablet / Desktop: batasi lebar maksimum dan sentrasi
        final maxWidth = screenWidth > 900 ? desktopMaxWidth : tabletMaxWidth;

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: padding != null
                ? Padding(padding: padding!, child: child)
                : child,
          ),
        );
      },
    );
  }
}

/// Versi ResponsiveWrapper untuk konten scrollable yang sudah memiliki
/// scroll view sendiri (misalnya ListView). Membungkus dengan Center + ConstrainedBox.
class ResponsiveScrollWrapper extends StatelessWidget {
  final Widget child;
  final double mobileBreakpoint;
  final double maxContentWidth;

  const ResponsiveScrollWrapper({
    super.key,
    required this.child,
    this.mobileBreakpoint = 600,
    this.maxContentWidth = 640,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < mobileBreakpoint) {
          return child;
        }

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: child,
          ),
        );
      },
    );
  }
}

