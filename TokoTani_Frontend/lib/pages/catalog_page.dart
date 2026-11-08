import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'cart_page.dart';
import 'product_detail_page.dart';

class CatalogPage extends StatefulWidget {
  final bool showBackButton;

  const CatalogPage({super.key, this.showBackButton = false});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  // 4 Keadaan Layar wajib sesuai Kriteria 7
  KeadaanMuat state = KeadaanMuat.memuat;
  List<Product> products = [];
  ApiException? lastError;

  // Penyaring dan Pencarian ke Server (Kriteria 2)
  String selectedKategori = 'Semua';
  final TextEditingController searchCtrl = TextEditingController();
  List<String> categories = ['Semua'];

  // Jumlah item di keranjang untuk badge ikon keranjang
  int cartItemCount = 0;
  bool isAddingToCart = false;

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadProducts();
    loadCartCount();
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> loadCategories() async {
    try {
      final serverCats = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        categories = ['Semua', ...serverCats.where((c) => c != 'Semua')];
      });
    } catch (_) {
      // Fallback kategori lokal bila terjadi galat
      if (!mounted) return;
      setState(() {
        categories = const [
          'Semua',
          'Sayuran',
          'Bumbu & Rempah',
          'Beras & Biji-bijian',
          'Buah-buahan',
          'Umbi-umbian',
        ];
      });
    }
  }

  Future<void> loadCartCount() async {
    try {
      final cart = await ApiService.getCart();
      if (!mounted) return;
      setState(() {
        cartItemCount = cart.items.fold<int>(0, (sum, i) => sum + i.jumlah);
      });
    } catch (_) {
      // Diam tanpa crash
    }
  }

  /// Memuat produk dari server dengan parameter ?kategori= dan ?cari=
  /// Bukan menyaring di memori aplikasi
  Future<void> loadProducts() async {
    setState(() {
      state = KeadaanMuat.memuat;
      lastError = null;
    });

    try {
      final result = await ApiService.getProducts(
        kategori: selectedKategori == 'Semua' ? null : selectedKategori,
        cari: searchCtrl.text.trim().isEmpty ? null : searchCtrl.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        products = result;
        state = result.isEmpty ? KeadaanMuat.kosong : KeadaanMuat.berhasil;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        lastError = e;
        state = KeadaanMuat.galat;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        lastError = const ApiException(
          statusCode: 500,
          message: 'Gagal memuat katalog produk dari server.',
          errorType: ApiErrorType.other,
        );
        state = KeadaanMuat.galat;
      });
    }
  }

  Future<void> quickAddToCart(Product product) async {
    if (isAddingToCart || !product.tersedia || product.stok <= 0) return;

    setState(() => isAddingToCart = true);

    try {
      await ApiService.addCart(product.id, 1);
      if (!mounted) return;
      await loadCartCount();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product.nama} (1 ${product.satuanJual}) masuk keranjang.',
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Lihat',
            textColor: Colors.amberAccent,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CartPage(showBackButton: true),
                ),
              );
              loadCartCount();
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      // Notifikasi galat di layar saat ini tanpa berpindah (Kriteria 6)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: e.statusCode == 409
              ? Colors.orange.shade900
              : Colors.red.shade800,
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
            content: Text(
              'Terjadi kesalahan sambungan saat menambah ke keranjang.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isAddingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: const Text('Katalog Produk Pertanian'),
        centerTitle: true,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          // Ikon keranjang belanja dengan lencana (badge) jumlah item
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined),
                tooltip: 'Keranjang Belanja',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CartPage(showBackButton: true),
                    ),
                  );
                  loadCartCount();
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      cartItemCount > 99 ? '99+' : '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: ResponsiveScrollWrapper(
        child: Column(
          children: [
            // Baris Pencarian Nama ke Server
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: searchCtrl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari produk pertanian...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF2E7D32),
                  ),
                  suffixIcon: searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchCtrl.clear();
                            loadProducts();
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => loadProducts(),
              ),
            ),

            // Penyaring Kategori ke Server
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = selectedKategori == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: const Color(0xFFE8F5E9),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF64748B),
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() => selectedKategori = cat);
                        loadProducts();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // 4 Keadaan Layar (Memuat, Berhasil, Kosong, Galat)
            Expanded(child: _buildBody()),
          ],
        ),
      ),
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
              Text('Memuat produk pertanian segar...'),
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    size: 56,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Produk Tidak Ditemukan',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  searchCtrl.text.isNotEmpty || selectedKategori != 'Semua'
                      ? 'Tidak ada produk yang cocok dengan pencarian "$searchCtrl.text" di kategori "$selectedKategori".'
                      : 'Belum ada produk pertanian yang terdaftar di sistem.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset Pencarian'),
                  onPressed: () {
                    searchCtrl.clear();
                    setState(() => selectedKategori = 'Semua');
                    loadProducts();
                  },
                ),
              ],
            ),
          ),
        );

      case KeadaanMuat.galat:
        return _buildErrorState();

      case KeadaanMuat.berhasil:
        return RefreshIndicator(
          onRefresh: loadProducts,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth > 500 ? 3 : 2;
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductCard(product);
                },
              );
            },
          ),
        );
    }
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stok <= 0 || !product.tersedia;

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(product: product),
          ),
        );
        loadCartCount();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar / Placeholder
            Expanded(
              flex: 5,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isOutOfStock
                          ? Colors.grey.shade100
                          : const Color(0xFFF1F8E9),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(15),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        product.mudahRusak
                            ? Icons.local_florist_rounded
                            : Icons.eco_rounded,
                        size: 48,
                        color: isOutOfStock
                            ? Colors.grey.shade400
                            : (product.mudahRusak
                                  ? Colors.orange.shade700
                                  : const Color(0xFF2E7D32)),
                      ),
                    ),
                  ),

                  // Badge Atribut Khas Domain (Mudah Rusak)
                  if (product.mudahRusak)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              'Same Day',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Penanda Produk Habis (Kriteria 3)
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                        ),
                        child: const Center(
                          child: ContainerBadge(
                            text: 'STOK HABIS',
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Detail Produk
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.kategori,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          product.nama,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? Colors.grey.shade600
                                : const Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatRupiah(product.harga),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isOutOfStock
                                ? Colors.grey.shade600
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          'per ${product.satuanJual} • Sisa ${product.stok}',
                          style: TextStyle(
                            fontSize: 10,
                            color: product.stok <= 5 && !isOutOfStock
                                ? Colors.orange.shade800
                                : const Color(0xFF64748B),
                            fontWeight: product.stok <= 5 && !isOutOfStock
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Tombol Tambah ke Keranjang (Dimatikan bila habis)
                        SizedBox(
                          width: double.infinity,
                          height: 32,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade600,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            icon: Icon(
                              isOutOfStock
                                  ? Icons.block_rounded
                                  : Icons.add_shopping_cart_rounded,
                              size: 14,
                            ),
                            label: Text(
                              isOutOfStock ? 'Habis' : '+ Keranjang',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: isOutOfStock
                                ? null
                                : () => quickAddToCart(product),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    IconData icon = Icons.error_outline;
    String title = 'Terjadi Kesalahan';
    String message = lastError?.message ?? 'Tidak dapat memuat katalog produk.';

    if (lastError != null) {
      switch (lastError!.errorType) {
        case ApiErrorType.connection:
          icon = Icons.wifi_off_rounded;
          title = 'Sambungan Gagal';
          break;
        case ApiErrorType.timeout:
          icon = Icons.timer_off_outlined;
          title = 'Batas Waktu Terlampaui';
          break;
        case ApiErrorType.server:
          icon = Icons.dns_outlined;
          title = 'Gangguan Server (500)';
          break;
        default:
          icon = Icons.cloud_off_rounded;
          break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              onPressed: loadProducts,
            ),
          ],
        ),
      ),
    );
  }
}

class ContainerBadge extends StatelessWidget {
  final String text;
  final Color color;

  const ContainerBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
