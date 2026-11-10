import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'order_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = auth.user;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colors.primary, colors.secondary],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, size: 60, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?['name']?.toString() ?? 'Pelanggan TaniMart',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?['email']?.toString() ?? 'pelanggan@email.com',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.white),
                      ),
                    ),
                    child: const Text('Ubah Profil'),
                  ),
                ],
              ),
            ),

            // Menu Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _menuItem(
                    context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Pesanan Saya',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OrderHistoryPage(showBackButton: true)),
                    ),
                  ),
                  _menuItem(
                    context,
                    icon: Icons.location_on_rounded,
                    title: 'Alamat Saya',
                    onTap: () {},
                  ),
                  _menuItem(
                    context,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Metode Pembayaran',
                    onTap: () {},
                  ),
                  const Divider(height: 32),
                  _menuItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'Pengaturan Aplikasi',
                    onTap: () => _showThemePicker(context, themeProvider),
                  ),
                  _menuItem(
                    context,
                    icon: Icons.help_outline_rounded,
                    title: 'Bantuan & FAQ',
                    onTap: () {},
                  ),
                  _menuItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'Tentang TaniMart',
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _confirmSignOut(context, auth),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Keluar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: colors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showThemePicker(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pengaturan Tema', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.light_mode_outlined),
              title: const Text('Terang'),
              trailing: provider.mode == ThemeMode.light ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                provider.setTheme(ThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode_outlined),
              title: const Text('Gelap'),
              trailing: provider.mode == ThemeMode.dark ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                provider.setTheme(ThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_brightness_outlined),
              title: const Text('Ikuti Sistem'),
              trailing: provider.mode == ThemeMode.system ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () {
                provider.setTheme(ThemeMode.system);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, AuthProvider auth) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      await auth.signOut();
    }
  }
}
