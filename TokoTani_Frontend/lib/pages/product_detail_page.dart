import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  final int productId;
  final Product? initialProduct;

  const ProductDetailPage({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  // 4 Keadaan Layar wajib
  KeadaanMuat state = KeadaanMuat.memuat;
  Product? product;
  ApiException? lastError;

  int quantity = 1;
  bool isAdding = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProduct != null) {
      product = widget.initialProduct;
      state = KeadaanMuat.berhasil;
    } else {
      loadProductDetail();
    }
  }

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> loadProductDetail() async {
    setState(() {
      state = KeadaanMuat.memuat;
      lastError = null;
    });

    try {
      final res = await ApiService.getProduct(widget.productId);
      if (!mounted) return;
      setState(() {
        product = res;
        state = KeadaanMuat.berhasil;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        lastError = e;
        state = e.statusCode == 404 ? KeadaanMuat.kosong : KeadaanMuat.galat;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        lastError = const ApiException(
          statusCode: 500,
          message: 'Gagal memuat rincian produk dari server.',
          errorType: ApiErrorType.other,
        );
        state = KeadaanMuat.galat;
      });
    }
  }

  Future<void> addToCart() async {
    final p = product;
    if (p == null || !p.tersedia || p.stok <= 0 || isAdding) return;

    setState(() => isAdding = true);

    try {
      await ApiService.addCart(p.id, quantity);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Berhasil menambahkan $quantity ${p.satuanJual} ke keranjang!'),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Menuju keranjang setelah berhasil menambah (Kriteria Perpindahan)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: e.statusCode == 409 ? Colors.orange.shade900 : Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          content: Text(e.message),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            content: Text('Terjadi kesalahan sambungan jaringan.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: Text(product?.nama ?? 'Rincian Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Keranjang',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartPage(showBackButton: true)),
              );
            },
          ),
        ],
      ),
      body: ResponsiveScrollWrapper(
        child: _buildBody(),
      ),
      bottomNavigationBar: state == KeadaanMuat.berhasil && product != null
          ? _buildBottomBar()
          : null,
    );
  }

  Widget _buildBody() {
    switch (state) {
      case KeadaanMuat.memuat:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2E7D32)),
              SizedBox(height: 16),
              Text('Memuat rincian produk...'),
            ],
          ),
        );

      case KeadaanMuat.kosong:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 64, color: Color(0xFF64748B)),
                const SizedBox(height: 16),
                const Text('Produk Tidak Ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Produk ini mungkin telah dihapus atau tidak lagi tersedia.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali ke Katalog'),
                ),
              ],
            ),
          ),
        );

      case KeadaanMuat.galat:
        return _buildErrorState();

      case KeadaanMuat.berhasil:
        final p = product!;
        final isOutOfStock = p.stok <= 0 || !p.tersedia;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Gambar Utama / Hero Card
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: isOutOfStock ? Colors.grey.shade200 : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Icon(
                  p.mudahRusak ? Icons.local_florist_rounded : Icons.eco_rounded,
                  size: 96,
                  color: isOutOfStock
                      ? Colors.grey.shade400
                      : (p.mudahRusak ? Colors.orange.shade700 : const Color(0xFF2E7D32)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori & Badge Domain (Mudah Rusak)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    p.kategori,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (p.mudahRusak)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, size: 14, color: Colors.orange.shade900),
                        const SizedBox(width: 4),
                        Text(
                          'Mudah Rusak (Wajib Same Day)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Nama Produk
            Text(
              p.nama,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),

            // Harga dan Satuan
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  formatRupiah(p.harga),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ ${p.satuanJual}',
                  style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status Ketersediaan & Stok
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isOutOfStock ? Icons.cancel_outlined : Icons.check_circle_outline,
                        color: isOutOfStock ? Colors.red : const Color(0xFF2E7D32),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOutOfStock ? 'Tidak Tersedia / Stok Habis' : 'Stok Tersedia',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isOutOfStock ? Colors.red : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${p.stok} ${p.satuanJual}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Deskripsi Produk
            const Text(
              'Deskripsi Produk',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              p.deskripsi != null && p.deskripsi!.trim().isNotEmpty
                  ? p.deskripsi!
                  : 'Produk pertanian berkualitas tinggi yang dipanen dan dikemas langsung dari petani lokal.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 20),

            // Kartu Profil Tani & Keunggulan Produk
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildTrustItem(
                    icon: Icons.place_outlined,
                    title: 'Asal Daerah Panen',
                    subtitle: 'Petani Mitra Nusantara (Jawa Timur & sekitarnya)',
                  ),
                  const Divider(height: 16),
                  _buildTrustItem(
                    icon: Icons.verified_user_outlined,
                    title: 'Jaminan Mutu & Kesegaran',
                    subtitle: '100% Produk Segar Langsung Dari Petani Lokal',
                  ),
                  const Divider(height: 16),
                  _buildTrustItem(
                    icon: Icons.local_shipping_outlined,
                    title: 'Metode Pengiriman',
                    subtitle: p.mudahRusak ? 'Wajib Same Day Demi Kesegaran Produk' : 'Tersedia Kurir Reguler & Instan',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Atribut Khas Domain Pertanian
            if (p.mudahRusak)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aturan Pengiriman Produk Segar',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Produk ini mudah layu/rusak. Pada saat checkout, sistem server mewajibkan pengiriman pada hari yang sama (Same Day) untuk menjaga kesegaran.',
                            style: TextStyle(fontSize: 12, color: Colors.orange.shade900, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  Widget _buildTrustItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF2E7D32), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final p = product!;
    final isOutOfStock = p.stok <= 0 || !p.tersedia;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -3),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  // Pemilih Kuantitas (- / +)
                  if (!isOutOfStock) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                          ),
                          Text(
                            '$quantity',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: quantity < p.stok ? () => setState(() => quantity++) : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Tombol Tambah ke Keranjang
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          disabledBackgroundColor: Colors.grey.shade300,
                          disabledForegroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: isAdding
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(isOutOfStock ? Icons.block : Icons.add_shopping_cart_rounded),
                        label: Text(
                          isOutOfStock ? 'Stok Tidak Tersedia' : 'Tambah ke Keranjang',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isOutOfStock || isAdding ? null : addToCart,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text('Gagal Memuat Produk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(lastError?.message ?? 'Terjadi kesalahan sistem.', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: loadProductDetail,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

