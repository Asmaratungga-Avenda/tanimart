import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'pages/login_page.dart';
import 'pages/main_shell.dart';
import 'pages/splash_page.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';
import 'widgets/app_button.dart';
import 'widgets/state_views.dart';

/// Akar aplikasi: seluruh provider dan MaterialApp berada di sini.
class TaniMartApp extends StatelessWidget {
  const TaniMartApp({
    super.key,
    this.home,
    this.initialThemeMode = ThemeMode.system,
  });

  /// Hanya untuk pengujian: menggantikan AuthGate.
  final Widget? home;
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(initialMode: initialThemeMode),
        ),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..bindUser(auth.userId),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (_) => OrderProvider(),
          update: (_, auth, orders) => orders!..bindUser(auth.userId),
        ),
      ],
      child: _AppView(home: home),
    );
  }
}

class _AppView extends StatelessWidget {
  const _AppView({this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    final mode = context.select<ThemeProvider, ThemeMode>((t) => t.mode);
    return MaterialApp(
      title: 'TaniMart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: ColoredBox(
          color: context.palette.background,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
      home: home ?? const AuthGate(),
    );
  }
}

/// Memilih layar awal: splash -> login -> aplikasi utama.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isInitializing) return const SplashPage();
    if (auth.isAuthenticated) return const MainShell();
    if (auth.sessionError != null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ErrorView(
                  title: 'Tidak dapat memeriksa sesi',
                  message: auth.sessionError!,
                  onRetry: auth.retrySession,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SecondaryButton(
                  label: 'Masuk dengan akun lain',
                  onPressed: auth.signOut,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const LoginPage();
  }
}
