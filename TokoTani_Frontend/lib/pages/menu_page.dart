import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import 'cart_page.dart';
import 'manage_product_page.dart';
import 'product_form_page.dart';

/// Halaman evaluasi dan navigasi tugas (dipertahankan untuk kompatibilitas uji otomatis)
class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('TokoTani - Menu Tugas'),
        backgroundColor: theme.primaryGreen,
        foregroundColor: theme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'TokoTani',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart_outlined, color: theme.primaryGreen),
              title: const Text('Keranjang Belanja'),
              subtitle: const Text('Subtotal server, ubah kuantitas, hapus item'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.inventory_2_outlined, color: theme.primaryGreen),
              title: const Text('Kelola Produk (CRUD)'),
              subtitle: const Text('Daftar produk dengan pencarian/kategori server'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ManageProductsPage()),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.add_box_outlined, color: theme.primaryGreen),
              title: const Text('Tambah Produk'),
              subtitle: const Text('Formulir produk baru'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductFormPage()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
