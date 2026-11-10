import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/ui.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/app_card.dart';

/// Akun: profil pelanggan, pintasan pesanan, pilihan tema, dan keluar.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final nav = context.read<NavigationProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDialog(
      context,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk berbelanja.',
      confirmLabel: 'Keluar',
      destructive: true,
    );
    if (!ok) return;
    final revoked = await auth.signOut();
    nav.reset();
    if (!revoked) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Anda sudah keluar di perangkat ini, tetapi server belum dapat dihubungi.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeMode = context.select<ThemeProvider, ThemeMode>((t) => t.mode);
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final name = auth.displayName;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [p.brand, BrandColors.deep],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: p.onBrand,
                      child: Text(
                        initial,
                        style: text.headlineSmall?.copyWith(
                          color: BrandColors.deep,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleLarge?.copyWith(color: p.onBrand),
                          ),
                          if (auth.email.isNotEmpty)
                            Text(
                              auth.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: p.onBrand.withValues(alpha: 0.9),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () =>
                      context.read<NavigationProvider>().select(AppTab.orders),
                  child: ListTile(
                    leading: Icon(Icons.receipt_long_outlined, color: p.brandText),
                    title: Text('Pesanan Saya', style: text.titleSmall),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Tampilan', style: text.titleMedium),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Terang'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Gelap'),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        icon: Icon(Icons.settings_suggest_outlined),
                        label: Text('Sistem'),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) => context
                        .read<ThemeProvider>()
                        .setMode(selection.first),
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.danger,
                      side: BorderSide(color: p.danger),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Keluar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
