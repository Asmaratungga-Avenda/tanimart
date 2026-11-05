// lib/main.dart
import 'package:flutter/material.dart';
import 'package:tokotani/views/halamanKatalog.dart';

void main() {
  runApp(const TokoTaniApp());
}

class TokoTaniApp extends StatelessWidget {
  const TokoTaniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toko Tani AgriMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      // Mengarahkan halaman utama langsung ke Halaman Katalog
      home: const HalamanKatalog(),
    );
  }
}