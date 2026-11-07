import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildApiModeToggle(context),
            const SizedBox(height: 14),
            _buildMenuSection(
              context,
              'Akun',
              [
                _MenuItem(
                  icon: Icons.person_outline,
                  title: 'Edit Profil',
                  subtitle: 'Budi Santoso',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Alamat Tersimpan',
                  subtitle: 'Kelola alamat pengiriman',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifikasi',
                  subtitle: 'Aktif',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildMenuSection(
              context,
              'Transaksi',
              [
                _MenuItem(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Riwayat Pesanan',
                  subtitle: 'Lihat semua pesanan',
                  onTap: () => _showComingSoon(context),
                ),
                _MenuItem(
                  icon: Icons.favorite_outline,
                  title: 'Produk Favorit',
                  subtitle: 'Produk yang kamu sukai',
                  onTap: () => _showComingSoon(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildMenuSection(
              context,
              'Tentang Aplikasi',
              [
                _MenuItem(
                  icon: Icons.info_outline,
                  title: 'Versi Aplikasi',
                  subtitle: 'Tani Mart v1.0.0',
                  onTap: () {},
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('v1.0.0',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen)),
                  ),
                ),
                _MenuItem(
                  icon: Icons.school_outlined,
                  title: 'Proyek Mahasiswa',
                  subtitle: 'Informatika · Aplikasi Mobile',
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.code_outlined,
                  title: 'Teknologi',
                  subtitle: 'Flutter · Laravel · MySQL',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.5), width: 3),
            ),
            child: const Center(
                child: Text('👨‍🌾', style: TextStyle(fontSize: 44))),
          ),
          const SizedBox(height: 14),
          Text(
            'Budi Santoso',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pelanggan Tani Mart',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statBox('3', 'Pesanan'),
              _divider(),
              _statBox('12', 'Produk\nDibeli'),
              _divider(),
              _statBox('Rp 270K', 'Total\nBelanja'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(value,
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                  height: 1.3)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 32,
      width: 1,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildApiModeToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: StatefulBuilder(
        builder: (ctx, setLocal) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ApiService.useMock
                      ? Colors.orange.shade50
                      : _lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  ApiService.useMock
                      ? Icons.science_outlined
                      : Icons.cloud_done_outlined,
                  color: ApiService.useMock
                      ? Colors.orange.shade700
                      : _primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ApiService.useMock ? 'Mode Data Tiruan' : 'Mode Laravel API',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      ApiService.useMock
                          ? 'Offline — data simulasi'
                          : ApiService.baseUrl,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: _textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: ApiService.useMock,
                activeThumbColor: _primaryGreen,
                onChanged: (val) {
                  setLocal(() => ApiService.useMock = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? 'Beralih ke Mode Data Tiruan (Offline)'
                          : 'Beralih ke Mode Laravel API'),
                      backgroundColor: val
                          ? Colors.orange.shade700
                          : _primaryGreen,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuSection(
      BuildContext context, String title, List<_MenuItem> items) {
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
                  color: _textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2)),
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
                      if (i > 0) const Divider(height: 1, indent: 16),
                      ListTile(
                        onTap: item.onTap,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _lightGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(item.icon,
                              color: _primaryGreen, size: 18),
                        ),
                        title: Text(item.title,
                            style: GoogleFonts.poppins(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                                color: _textPrimary)),
                        subtitle: Text(item.subtitle,
                            style: GoogleFonts.poppins(
                                fontSize: 11.5, color: _textSecondary)),
                        trailing: item.trailing ??
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 20),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
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

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fitur ini akan segera hadir! 🚀'),
        backgroundColor: _primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
}

