import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/courier.dart';
import '../models/payment_method.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';

class CheckoutPage extends StatefulWidget {
  final List<CartItem>? items;
  final int? subtotal;

  const CheckoutPage({
    super.key,
    this.items,
    this.subtotal,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Data pengiriman & form
  final _formKey = GlobalKey<FormState>();
  String _namaPenerima = 'Budi Santoso';
  String _alamatPenerima = 'Jl. Melati No. 123, Lowokwaru, Kota Malang';
  DateTime _tanggalAntar = DateTime.now();

  // Data barang — langsung dari widget.items bila ada, bukan async
  List<CartItem> _items = [];
  // Loading hanya berlaku jika items belum ada (harus ambil dari server)
  bool _isLoading = false;
  bool _isSubmitting = false;

  // Sorting barang berdasarkan jumlah: default descending (terbanyak di paling atas)
  bool _sortAscending = false;

  // Kurir & Pembayaran dengan data default langsung (tidak async di initState)
  final List<Courier> _couriers = const [
    Courier(id: 1, nama: 'JNE Regular', tarif: 15000, aktif: true),
    Courier(id: 2, nama: 'SiCepat HALU', tarif: 12000, aktif: true),
    Courier(id: 3, nama: 'Gojek Instant', tarif: 25000, aktif: true),
  ];
  Courier? _selectedCourier;

  final List<PaymentMethod> _paymentMethods = const [
    PaymentMethod(
      id: 1,
      nama: 'COD (Bayar di Tempat)',
      deskripsi: 'Bayar saat pesanan tiba di tujuan',
      aktif: true,
    ),
    PaymentMethod(
      id: 2,
      nama: 'Transfer Bank',
      deskripsi: 'Transfer melalui rekening BCA / BRI / Mandiri',
      aktif: true,
    ),
  ];
  PaymentMethod? _selectedPayment;

  @override
  void initState() {
    super.initState();

    // Jika items sudah dikirim dari halaman sebelumnya (CartPage), langsung pakai
    if (widget.items != null && widget.items!.isNotEmpty) {
      _items = List<CartItem>.from(widget.items!);
    }

    // Kurir & payment method default sudah diinisialisasi di field declaration
    _selectedCourier = _couriers.first;
    _selectedPayment = _paymentMethods.first;

    // Fetch data dari server hanya jika items belum ada (opsional, background)
    if (_items.isEmpty) {
      _fetchCartFromServer();
    }
  }

  Future<void> _fetchCartFromServer() async {
    setState(() => _isLoading = true);
    try {
      final cartResp = await ApiService.getCart();
      if (!mounted) return;
      setState(() {
        _items = cartResp.items;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Urutan barang dari atas sampai bawah sesuai dengan jumlah barangnya
  List<CartItem> get _sortedItems {
    final list = List<CartItem>.from(_items);
    if (_sortAscending) {
      // Ascending: jumlah sedikit ke banyak
      list.sort((a, b) => a.jumlah.compareTo(b.jumlah));
    } else {
      // Descending: jumlah terbanyak di atas ke paling sedikit di bawah
      list.sort((a, b) => b.jumlah.compareTo(a.jumlah));
    }
    return list;
  }

  int get _calculatedSubtotal {
    if (widget.subtotal != null && widget.subtotal! > 0) {
      return widget.subtotal!;
    }
    return _items.fold<int>(0, (sum, item) => sum + (item.harga * item.jumlah));
  }

  int get _ongkir => _selectedCourier?.tarif ?? 0;
  int get _totalBayar => _calculatedSubtotal + _ongkir;

  String _formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  void _showEditAddressDialog() {
    final namaCtrl = TextEditingController(text: _namaPenerima);
    final alamatCtrl = TextEditingController(text: _alamatPenerima);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.edit_location_alt_outlined, color: Color(0xFF2E7D32)),
            SizedBox(width: 8),
            Text('Ubah Data Penerima', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: namaCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Penerima',
                hintText: 'Masukkan nama penerima...',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: alamatCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat Pengiriman',
                hintText: 'Masukkan alamat lengkap pengiriman...',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () {
              if (namaCtrl.text.trim().isNotEmpty && alamatCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _namaPenerima = namaCtrl.text.trim();
                  _alamatPenerima = alamatCtrl.text.trim();
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalAntar.isBefore(now) ? now : _tanggalAntar,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2E7D32),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _tanggalAntar = picked);
    }
  }

  Future<void> _processCheckout() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedCourier == null || _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kurir dan metode pembayaran terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'nama_penerima': _namaPenerima,
      'alamat_penerima': _alamatPenerima,
      'kurir_id': _selectedCourier!.id,
      'payment_method_id': _selectedPayment!.id,
      'tanggal_antar': '${_tanggalAntar.year}-${_tanggalAntar.month.toString().padLeft(2, '0')}-${_tanggalAntar.day.toString().padLeft(2, '0')}',
      'items': _items.map((i) => {'product_id': i.produkId, 'quantity': i.jumlah}).toList(),
    };

    try {
      final res = await ApiService.checkout(payload);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSuccessDialog(res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses checkout: $e'),
          backgroundColor: Colors.red.shade800,
        ),
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 48),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pesanan Berhasil Dibuat!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pesanan atas nama $_namaPenerima telah diterima dan sedang dipersiapkan oleh petani lokal.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kurir Pengiriman', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(_selectedCourier?.nama ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Metode Bayar', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(_selectedPayment?.nama ?? '-', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        Text(
                          _formatRupiah(_totalBayar),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(ctx); // tutup dialog
                Navigator.pop(context, true); // kembali ke halaman sebelumnya
              },
              child: const Text('Selesai & Kembali'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _sortedItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: const Text(
          'Checkout Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2E7D32)),
                  SizedBox(height: 12),
                  Text('Menyiapkan data checkout...'),
                ],
              ),
            )
          : ResponsiveScrollWrapper(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    // ==========================================
                    // 1. DAFTAR BARANG CHECKOUT (MODEL LIST KE BAWAH)
                    // ==========================================
                    _buildSectionHeader(
                      title: 'Daftar Barang',
                      subtitle: 'Barang diurutkan ke bawah sesuai dengan jumlahnya',
                      actionWidget: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${sortedItems.length} Produk',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Kontrol Urutan (Sorting Berdasarkan Jumlah)
                    _buildSortControlBadge(),
                    const SizedBox(height: 10),

                    // Model List Barang ke Bawah
                    if (sortedItems.isEmpty)
                      _buildEmptyItemState()
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = sortedItems[index];
                          final rankNumber = index + 1;
                          return _buildCheckoutItemCard(item, rankNumber);
                        },
                      ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 2. INFORMASI ALAMAT PENGIRIMAN
                    // ==========================================
                    _buildSectionHeader(
                      title: 'Alamat Pengiriman',
                      subtitle: 'Pesanan akan dikirim ke lokasi ini',
                    ),
                    const SizedBox(height: 8),
                    _buildAddressCard(),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 3. TANGGAL PENGIRIMAN
                    // ==========================================
                    _buildSectionHeader(
                      title: 'Jadwal Pengiriman',
                      subtitle: 'Pilih waktu pengiriman produk tani segar',
                    ),
                    const SizedBox(height: 8),
                    _buildDeliveryDateCard(),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 4. PILIHAN KURIR PENGIRIMAN
                    // ==========================================
                    _buildSectionHeader(
                      title: 'Kurir Pengiriman',
                      subtitle: 'Pilih jasa pengiriman yang tersedia',
                    ),
                    const SizedBox(height: 8),
                    _buildCourierSelectionCard(),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 5. METODE PEMBAYARAN
                    // ==========================================
                    _buildSectionHeader(
                      title: 'Metode Pembayaran',
                      subtitle: 'Pilih opsi pembayaran yang Anda inginkan',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentMethodCard(),

                    const SizedBox(height: 24),

                    // ==========================================
                    // 6. RINGKASAN BIAYA
                    // ==========================================
                    _buildSectionHeader(
                      title: 'Rincian Pembayaran',
                      subtitle: 'Total tagihan yang harus dibayar',
                    ),
                    const SizedBox(height: 8),
                    _buildPriceSummaryCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // -------------------------------------------------------------
  // WIDGET KOMPONEN TAMPILAN
  // -------------------------------------------------------------

  Widget _buildSectionHeader({
    required String title,
    String? subtitle,
    Widget? actionWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ],
          ),
        ),
        ?actionWidget,
      ],
    );
  }

  /// Chip penanda urutan barang sesuai dengan jumlahnya
  Widget _buildSortControlBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.sort_rounded, size: 18, color: Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sortAscending
                        ? 'Urutan: Jumlah Tersedikit (Naik ↑)'
                        : 'Urutan: Jumlah Terbanyak (Turun ↓)',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 14,
                    color: const Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Ubah Urutan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
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

  /// Model Card List Barang dengan komponen:
  /// 1. Nama Barang
  /// 2. Harga (harga satuan dan total per barang)
  /// 3. Jumlah Barang (jumlah & satuan jual)
  Widget _buildCheckoutItemCard(CartItem item, int rank) {
    final totalPerItem = item.harga * item.jumlah;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Urutan posisi barang (Rank dari atas ke bawah)
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? const Color(0xFF2E7D32) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Thumbnail / Icon Produk
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.eco, size: 26, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(width: 12),

          // Komponen Nama Barang & Harga
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KOMPONEN 1: NAMA BARANG
                Text(
                  item.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // KOMPONEN 2: HARGA SATUAN
                Text(
                  '${_formatRupiah(item.harga)} / ${item.satuanJual}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 4),

                // Subtotal harga item
                Text(
                  _formatRupiah(totalPerItem),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),

          // KOMPONEN 3: JUMLAH BARANG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Jumlah',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.jumlah} ${item.satuanJual}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyItemState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Center(
        child: Column(
          children: [
            Icon(Icons.remove_shopping_cart_outlined, size: 40, color: Color(0xFF94A3B8)),
            SizedBox(height: 8),
            Text(
              'Tidak ada barang untuk di-checkout.',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.location_on, color: Color(0xFF2E7D32), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _namaPenerima,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 3),
                Text(
                  _alamatPenerima,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showEditAddressDialog,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text('Ubah', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDateCard() {
    final dateStr = '${_tanggalAntar.day.toString().padLeft(2, '0')}/${_tanggalAntar.month.toString().padLeft(2, '0')}/${_tanggalAntar.year}';

    return Container(
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2E7D32), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tanggal Antar', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2E7D32),
              side: const BorderSide(color: Color(0xFF2E7D32)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            icon: const Icon(Icons.edit_calendar_outlined, size: 16),
            label: const Text('Pilih Tanggal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            onPressed: _pickDeliveryDate,
          ),
        ],
      ),
    );
  }

  Widget _buildCourierSelectionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: _couriers.map((courier) {
          final isSelected = _selectedCourier?.id == courier.id;
          return InkWell(
            onTap: () => setState(() => _selectedCourier = courier),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: courier != _couriers.last
                      ? const BorderSide(color: Color(0xFFF1F5F9))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      courier.nama,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Text(
                    _formatRupiah(courier.tarif),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: _paymentMethods.map((pm) {
          final isSelected = _selectedPayment?.id == pm.id;
          return InkWell(
            onTap: () => setState(() => _selectedPayment = pm),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: pm != _paymentMethods.last
                      ? const BorderSide(color: Color(0xFFF1F5F9))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pm.nama,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (pm.deskripsi != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            pm.deskripsi!,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal Produk', _formatRupiah(_calculatedSubtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow('Ongkos Kirim (${_selectedCourier?.nama ?? '-'})', _formatRupiah(_ongkir)),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Pembayaran',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                _formatRupiah(_totalBayar),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            offset: const Offset(0, -4),
            blurRadius: 14,
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
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Pembayaran',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRupiah(_totalBayar),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _isSubmitting ? null : _processCheckout,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Buat Pesanan',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                            ],
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
}
