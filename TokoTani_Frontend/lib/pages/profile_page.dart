import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_extension.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';
import 'notifications_page.dart';
import 'order_history_page.dart';
import 'product_catalog_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryGreen = AppTheme.getPrimaryGreen(isDark);
    final lightGreen = AppTheme.getLightGreen(isDark);
    final textPrimary = AppTheme.getTextPrimaryColor(isDark);
    final textSecondary = AppTheme.getTextSecondaryColor(isDark);
    final surfaceColor = AppTheme.getSurfaceColor(isDark);
    final backgroundColor = AppTheme.getBackgroundColor(isDark);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(isDark, primaryGreen),
            const SizedBox(height: 20),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final user = auth.user;
                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.of(context).shadowColor,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_circle_outlined,
                        color: primaryGreen,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?['name']?.toString() ?? 'Pelanggan',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user?['email']?.toString() ?? '',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _buildMenuSection(
              context,
              'Akun',
              textPrimary,
              textSecondary,
              surfaceColor,
              primaryGreen,
              lightGreen,
              [
                _MenuItem(
                  icon: Icons.logout,
                  title: 'Keluar',
                  subtitle: 'Akhiri sesi akun ini',
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () => _confirmSignOut(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) => _buildThemeSection(
                context,
                themeProvider,
                textPrimary,
                textSecondary,
                surfaceColor,
                primaryGreen,
                lightGreen,
              ),
            ),
            const SizedBox(height: 14),
            ValueListenableBuilder<int>(
              valueListenable: NotificationService.unreadCountNotifier,
              builder: (context, unread, _) => _buildMenuSection(
                context,
                'Notifikasi',
                textPrimary,
                textSecondary,
                surfaceColor,
                primaryGreen,
                lightGreen,
                [
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifikasi',
                    subtitle: unread > 0
                        ? '$unread notifikasi baru'
                        : 'Tidak ada notifikasi baru',
                    iconColor: primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsPage(),
                        ),
                      );
                    },
                    trailing: unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.getErrorRed(isDark),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$unread',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _buildMenuSection(
              context,
              'Transaksi',
              textPrimary,
              textSecondary,
              surfaceColor,
              primaryGreen,
              lightGreen,
              [
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Riwayat Pesanan',
                  subtitle: 'Lihat semua pesanan',
                  iconColor: primaryGreen,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderHistoryPage(
                        showBackButton: true,
                        onGoToCatalog: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProductCatalogPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda perlu masuk kembali untuk melihat keranjang dan pesanan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (shouldSignOut != true || !context.mounted) return;

    final revoked = await context.read<AuthProvider>().signOut();
    if (!context.mounted || revoked) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Sesi di perangkat ini telah ditutup, tetapi token server belum dapat dicabut.',
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryGreen) {
    final foreground = isDark
        ? AppTheme.darkTextPrimary
        : AppTheme.lightSurface;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.darkBackground, AppTheme.darkSurface]
              : [primaryGreen, AppTheme.lightSecondaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: foreground.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: foreground.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
            child: Icon(Icons.eco_rounded, color: foreground, size: 38),
          ),
          const SizedBox(height: 14),
          Text(
            'Profil & Pengaturan',
            style: GoogleFonts.poppins(
              color: foreground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Preferensi dan aktivitas Tani Mart',
            style: GoogleFonts.poppins(
              color: foreground.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    ThemeProvider themeProvider,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color primaryGreen,
    Color lightGreen,
  ) {
    final activeDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Pengaturan Tampilan',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.of(context).shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: lightGreen,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        activeDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        color: primaryGreen,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      activeDark ? 'Mode Gelap' : 'Mode Terang',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      activeDark
                          ? 'Tampilan gelap untuk kenyamanan malam hari'
                          : 'Tampilan terang untuk kenyamanan siang hari',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: textSecondary,
                      ),
                    ),
                    trailing: DropdownButtonHideUnderline(
                      child: DropdownButton<ThemeMode>(
                        value: themeProvider.mode,
                        borderRadius: BorderRadius.circular(12),
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Terang'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Gelap'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('Sistem'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) themeProvider.setTheme(mode);
                        },
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context,
    String title,
    Color textPrimary,
    Color textSecondary,
    Color surfaceColor,
    Color primaryGreen,
    Color lightGreen,
    List<_MenuItem> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textSecondary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.of(context).shadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Column(
                    children: [
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 16,
                          color: AppTheme.getBorderColor(isDark(context)),
                        ),
                      ListTile(
                        onTap: item.onTap,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            item.icon,
                            color: item.iconColor,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          item.subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: textSecondary,
                          ),
                        ),
                        trailing:
                            item.trailing ??
                            Icon(
                              Icons.chevron_right,
                              color: textSecondary,
                              size: 20,
                            ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.iconColor,
    this.trailing,
  });
}
