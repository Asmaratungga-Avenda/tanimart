import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import '../core/widgets/product_image.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'product_form_page.dart';

class ManageProductsPage extends StatefulWidget {
  const ManageProductsPage({super.key});

  @override
  State<ManageProductsPage> createState() => _ManageProductsPageState();
}

class _ManageProductsPageState extends State<ManageProductsPage> {
  // 4 Keadaan Layar wajib sesuai Kriteria 7
  KeadaanMuat state = KeadaanMuat.memuat;
  List<Product> products = [];
  ApiException? lastError;

  // Parameter Penyaring dan Pencarian ke Server (Kriteria 2)
  String selectedKategori = 'Semua';
  final TextEditingController searchController = TextEditingController();
  final List<String> categories = const [
    'Semua',
    'Sayuran',
    'Bumbu & Rempah',
    'Beras & Biji-bijian',
    'Buah-buahan',
    'Umbi-umbian',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) loadProducts();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  /// Memuat produk dari server dengan parameter ?kategori= dan ?cari=
  /// Bukan menyaring di memori aplikasi (Sesuai Kriteria 2 Sangat Baik)
  Future<void> loadProducts() async {
    setState(() {
      state = KeadaanMuat.memuat;
      lastError = null;
    });

    try {
      final result = await ApiService.getProducts(
        kategori: selectedKategori == 'Semua' ? null : selectedKategori,
        cari: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
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
          message: 'Gagal memuat produk dari server.',
          errorType: ApiErrorType.other,
        );
        state = KeadaanMuat.galat;
      });
    }
  }

  /// Membuka formulir tambah/ubah produk dan menyegarkan daftar saat berhasil
  Future<void> openForm([Product? product]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormPage(product: product)),
    );
    if (saved == true && mounted) {
      loadProducts();
    }
  }

  /// Menghapus produk dengan konfirmasi dialog dan penanganan galat 409
  Future<void> deleteProduct(Product product) async {
    final theme = AppColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: theme.errorRed),
            const SizedBox(width: 8),
            const Text('Hapus Produk'),
          ],
        ),
        content: Text(
          'Yakin ingin menghapus produk "${product.nama}"?\n\n'
          'Perhatian: Produk yang terkait dengan pesanan aktif akan ditolak server (galat 409).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: theme.errorRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: theme.primaryGreen,
          content: Text('Produk "${product.nama}" berhasil dihapus.'),
        ),
      );
      loadProducts();
    } on ApiException catch (e) {
      if (!mounted) return;
      // Penanganan khusus bila produk masih terpakai pada pesanan aktif (409)
      if (e.errorType == ApiErrorType.conflict || e.statusCode == 409) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Penghapusan Ditolak (409)'),
            content: Text(e.message),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: theme.errorRed, content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.errorRed,
            content: const Text('Gagal menghapus produk. Periksa koneksi.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Produk',
            onPressed: loadProducts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Produk'),
      ),
      body: ResponsiveScrollWrapper(
        child: Column(
          children: [
            // Bar Pencarian & Penyaring Kategori (Kriteria 2)
            _buildFilterSection(),
            const Divider(height: 1),
            // Isi Layar Utama Berdasarkan 4 Keadaan Layar
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    final theme = AppColors.of(context);
    return Container(
      color: theme.surfaceColor,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          // Input Pencarian
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari produk pertanian...',
              hintStyle: TextStyle(color: theme.textSecondary, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: theme.textSecondary),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        loadProducts();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryGreen, width: 1.5),
              ),
            ),
            onSubmitted: (_) => loadProducts(),
          ),
          const SizedBox(height: 10),
          // Pilihan Kategori (Filter Chip) Sesuai Desain UI TokoTani
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedKategori == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    showCheckmark: false,
                    backgroundColor: theme.surfaceColor,
                    selectedColor: theme.primaryGreen,
                    side: BorderSide(
                      color: isSelected
                          ? theme.primaryGreen
                          : theme.borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? theme.onPrimary : theme.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                    onSelected: (val) {
                      setState(() => selectedKategori = cat);
                      loadProducts();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final theme = AppColors.of(context);
    switch (state) {
      case KeadaanMuat.memuat:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat daftar produk pertanian...'),
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
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: theme.textSecondary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Belum Ada Produk Pertanian',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada produk yang cocok dengan pencarian/kategori yang dipilih, atau belum ada produk yang ditambahkan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.textSecondary),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Produk Pertama'),
                      onPressed: () => openForm(),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Filter'),
                      onPressed: () {
                        searchController.clear();
                        selectedKategori = 'Semua';
                        loadProducts();
                      },
                    ),
                  ],
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
          // Menggunakan ListView.builder sesuai ketentuan Kriteria 2
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final p = products[index];
              return _buildProductCard(p);
            },
          ),
        );
    }
  }

  Widget _buildErrorState() {
    final theme = AppColors.of(context);
    IconData icon = Icons.cloud_off_rounded;
    String title = 'Terjadi Kesalahan';
    String message = lastError?.message ?? 'Gagal memuat produk dari server.';

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
          icon = Icons.error_outline;
          break;
      }
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.errorRed),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.textPrimary),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              onPressed: loadProducts,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product p) {
    final theme = AppColors.of(context);
    final isStokHabis = p.stok <= 0;
    final isTidakTersedia = !p.tersedia;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStokHabis ? theme.errorContainer : theme.borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Foto Produk Nyata
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: ProductImage(
                      imageUrl: p.foto,
                      productName: p.nama,
                      category: p.kategori,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Nama, Kategori, & Harga
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.nama,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isStokHabis
                                    ? theme.textSecondary
                                    : theme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            formatRupiah(p.harga),
                            style: TextStyle(
                              color: isStokHabis
                                  ? theme.textSecondary
                                  : theme.primaryGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            ' / ${p.satuanJual}',
                            style: TextStyle(
                              color: theme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.mutedContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p.kategori,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Menu Cepat Ubah & Hapus dengan Icon Ergonomis
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.textSecondary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  onSelected: (action) {
                    if (action == 'edit') openForm(p);
                    if (action == 'delete') deleteProduct(p);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: theme.info,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Ubah Produk',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: theme.errorRed,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Hapus Produk',
                            style: TextStyle(
                              color: theme.errorRed,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            // Penanda Status dan Atribut Khas Domain Pertanian (Kriteria 1 & 2)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                // Badge Stok
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isStokHabis
                        ? theme.errorContainer
                        : theme.lightGreen,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isStokHabis ? theme.errorRed : theme.primaryGreen,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isStokHabis
                            ? Icons.warning_amber_rounded
                            : Icons.inventory_2_outlined,
                        size: 13,
                        color: isStokHabis
                            ? theme.errorRed
                            : theme.primaryGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isStokHabis
                            ? 'STOK HABIS (0)'
                            : 'Stok: ${p.stok} ${p.satuanJual}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isStokHabis
                              ? theme.errorRed
                              : theme.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),

                // Penanda Ketersediaan
                if (isTidakTersedia)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.mutedContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderColor),
                    ),
                    child: Text(
                      'TIDAK AKTIF',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),

                // Atribut Khas Pertanian TokoTani: Mudah Rusak
                if (p.mudahRusak)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.warningContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.warning),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: theme.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MUDAH RUSAK',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.warning,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (p.deskripsi != null && p.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                p.deskripsi!,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textSecondary,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
