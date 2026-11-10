import 'package:flutter/material.dart';

/// Ikon kategori berdasarkan kata kunci nama (nama kategori berasal dari API).
IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('sayur')) return Icons.eco_outlined;
  if (n.contains('buah')) return Icons.local_florist_outlined;
  if (n.contains('bibit') || n.contains('benih')) return Icons.spa_outlined;
  if (n.contains('pupuk')) return Icons.grass_outlined;
  if (n.contains('alat')) return Icons.agriculture_outlined;
  if (n.contains('pangan') ||
      n.contains('beras') ||
      n.contains('sembako') ||
      n.contains('harian')) {
    return Icons.shopping_basket_outlined;
  }
  if (n.contains('bumbu') || n.contains('rempah')) {
    return Icons.restaurant_outlined;
  }
  return Icons.category_outlined;
}
