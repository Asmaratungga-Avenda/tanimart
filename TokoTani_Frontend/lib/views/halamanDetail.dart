import 'package:flutter/material.dart';

class HalamanDetail extends StatefulWidget {
  final Map<String, dynamic> produk;

  const HalamanDetail({super.key, required this.produk});

  @override
  State<HalamanDetail> createState() => _HalamanDetailState();
}

class _HalamanDetailState extends State<HalamanDetail> {
  int _jumlahBeli = 1;

  @override
  Widget build(BuildContext context) {
    final produk = widget.produk;
    final int stok = produk['stok'] ?? 0;
    final bool mudahRusak = produk['mudah_rusak'] == 1 || produk['mudah_rusak'] == true;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Rincian Produk',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.redAccent),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Visual Produk
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.green.shade50,
              child: const Center(
                child: Icon(Icons.eco, size: 100, color: Colors.green),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Status Produk (Mudah Rusak / Produk Lokal)
                  Row(
                    children: [
                      if (mudahRusak)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Cepat Rusak',
                            style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '✔ Produk Lokal',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Nama Produk
                  Text(
                    produk['nama_produk'] ?? produk['nama'] ?? 'Tanpa Nama',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 6),

                  // Harga dan Satuan Jual
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rp ${produk['harga'] ?? 0}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      Text(
                        ' /${produk['satuan_jual'] ?? 'kg'}',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),

                  // Deskripsi Produk
                  const Text(
                    'Deskripsi Produk',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    produk['deskripsi'] ?? 'Produk segar langsung dari petani lokal, kualitas terbaik.',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Informasi Stok
                  Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        'Stok Tersedia: $stok ${produk['satuan_jual'] ?? 'kg'}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Selector Jumlah (Quantity)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Jumlah Pembelian',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _jumlahBeli > 1
                                ? () => setState(() => _jumlahBeli--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_jumlahBeli',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _jumlahBeli < stok
                                ? () => setState(() => _jumlahBeli++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation Bar (Tombol Tambah Ke Keranjang)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: stok > 0
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Berhasil menambahkan $_jumlahBeli ${produk['satuan_jual']} ke keranjang!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              : null,
          child: Text(
            stok > 0 ? 'Tambah ke Keranjang' : 'Stok Habis',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}