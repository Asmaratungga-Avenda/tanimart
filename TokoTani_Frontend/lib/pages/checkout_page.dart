import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/courier.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../core/theme/theme_extension.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';
import 'order_detail_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Data pengiriman & form
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _alamatCtrl;
  String _namaPenerima = '';
  String _alamatPenerima = '';
  DateTime _tanggalAntar = DateTime.now();

  // Kunci Idempoten (Kriteria 4 Checkout: dibuat sekali per percobaan, dipakai ulang saat coba lagi)
  String? _idempotencyKey;

  // Galat spesifik
  Map<String, String> _serverErrors = {};
  String? _conflictError;
  ApiException? _generalError;

  // Data barang — langsung dari CartProvider (Single Source of Truth)
  bool _isSubmitting = false;
  bool _isLoadingOptions = true;
  String? _optionsError;

  // Sorting barang berdasarkan jumlah: default descending (terbanyak di paling atas)
  bool _sortAscending = false;

  // Kurir & Pembayaran dengan data default langsung (tidak async di initState)
  List<Courier> _couriers = [];
  Courier? _selectedCourier;

  List<PaymentMethod> _paymentMethods = [];
  PaymentMethod? _selectedPayment;

  @override
  void initState() {
    super.initState();

    _namaCtrl = TextEditingController(text: _namaPenerima);
    _alamatCtrl = TextEditingController(text: _alamatPenerima);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartProvider>().loadCart();
      _loadCouriersAndPayments();
    });
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _alamatCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCouriersAndPayments() async {
    setState(() {
      _isLoadingOptions = true;
      _optionsError = null;
    });
    try {
      final couriers = await ApiService.getCouriers();
      final payments = await ApiService.getPaymentMethods();
      if (!mounted) return;
      setState(() {
        _couriers = couriers;
        _selectedCourier = couriers.isEmpty ? null : couriers.first;
        _paymentMethods = payments;
        _selectedPayment = payments.isEmpty ? null : payments.first;
        if (couriers.isEmpty || payments.isEmpty) {
          _optionsError = 'Kurir atau metode pembayaran belum tersedia.';
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _optionsError = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _optionsError = 'Gagal memuat pilihan checkout: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingOptions = false);
      }
    }
  }

  /// Urutan barang dari atas sampai bawah sesuai dengan jumlah barangnya
  List<CartItem> get _sortedItems {
    final cart = context.read<CartProvider>();
    final list = List<CartItem>.from(cart.items);
    if (_sortAscending) {
      // Ascending: jumlah sedikit ke banyak
      list.sort((a, b) => a.jumlah.compareTo(b.jumlah));
    } else {
      // Descending: jumlah terbanyak di atas ke paling sedikit di bawah
      list.sort((a, b) => b.jumlah.compareTo(a.jumlah));
    }
    return list;
  }

  int get _calculatedSubtotal => context.read<CartProvider>().subtotal;

  int get _ongkir => _selectedCourier?.tarif ?? 0;
  int get _totalBayar => _calculatedSubtotal + _ongkir;

  String _formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> _pickDeliveryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalAntar.isBefore(now) ? now : _tanggalAntar,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() => _tanggalAntar = picked);
    }
  }

  Future<void> _processCheckout() async {
    final theme = AppColors.of(context);
    setState(() {
      _serverErrors.clear();
      _conflictError = null;
      _generalError = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCourier == null || _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pilih kurir dan metode pembayaran terlebih dahulu.'),
          backgroundColor: theme.warning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Keranjang belanja kosong!'),
          backgroundColor: theme.errorRed,
        ),
      );
      setState(() => _isSubmitting = false);
      return;
    }

    // Kunci Idempoten: dibuat sekali per percobaan, dipakai ulang ketika menekan coba lagi
    _idempotencyKey ??= 'IDEMP-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(999999)}';

    final payload = {
      'nama_penerima': _namaCtrl.text.trim(),
      'alamat_penerima': _alamatCtrl.text.trim(),
      'kurir_id': _selectedCourier!.id,
      'payment_method_id': _selectedPayment!.id,
      'tanggal_antar': '${_tanggalAntar.year}-${_tanggalAntar.month.toString().padLeft(2, '0')}-${_tanggalAntar.day.toString().padLeft(2, '0')}',
      'items': cart.items.map((i) => {'product_id': i.produkId, 'quantity': i.jumlah}).toList(),
    };

    try {
      final res = await ApiService.checkout(payload, idempotencyKey: _idempotencyKey);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _idempotencyKey = null; // Berhasil, bersihkan kunci idempoten

      final orderData = res['data'];
      if (orderData is! Map) {
        throw const FormatException('Checkout response is missing order data.');
      }
      final orderId = int.tryParse(
        '${orderData['id'] ?? orderData['order_id'] ?? ''}',
      );
      if (orderId == null || orderId <= 0) {
        throw const FormatException('Checkout response is missing a valid order ID.');
      }
      final orderModel = OrderModel.fromJson(
        Map<String, dynamic>.from(orderData),
      );

      // Menuju rincian pesanan setelah 201 (Kriteria Perpindahan)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => OrderDetailPage(
            orderId: orderId,
            initialOrder: orderModel,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (e.statusCode == 422 || e.errorType == ApiErrorType.validation) {
        // Validasi gagal 422: tampilkan galat per kolom di bawah kolom bersangkutan
        setState(() {
          _serverErrors = e.fieldErrors;
        });
        _formKey.currentState?.validate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.warning,
            behavior: SnackBarBehavior.floating,
            content: Text('Validasi formulir gagal. Periksa kolom yang bertanda merah.'),
          ),
        );
      } else if (e.statusCode == 409 || e.errorType == ApiErrorType.conflict) {
        // Bentrok keadaan 409: pesan server di layar yang sedang dibuka, tanpa berpindah
        setState(() {
          _conflictError = e.message;
        });
      } else {
        // Sambungan gagal, batas waktu terlampaui, galat 500: tampilkan banner + tombol coba lagi
        setState(() {
          _generalError = e;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _generalError = const ApiException(
          statusCode: 500,
          message: 'Respons checkout tidak lengkap atau tidak dapat dibaca. Pesanan belum dikonfirmasi.',
          errorType: ApiErrorType.server,
        );
      });
      debugPrint('Checkout response could not be processed: $e');
    }
  }

  Widget _buildConflictErrorBanner() {
    final theme = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.errorRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.errorRed, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bentrok Keadaan (409)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.errorRed),
                ),
                const SizedBox(height: 4),
                Text(
                  _conflictError!,
                  style: TextStyle(color: theme.errorRed, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _conflictError = null),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralErrorBanner() {
    final theme = AppColors.of(context);
    final err = _generalError!;
    final isConn = err.errorType == ApiErrorType.connection;
    final isTimeout = err.errorType == ApiErrorType.timeout;
    final isServer = err.errorType == ApiErrorType.server;

    final title = isConn
        ? 'Tidak Ada Sambungan'
        : isTimeout
            ? 'Batas Waktu Terlampaui'
            : isServer
                ? 'Galat Server (500)'
                : 'Gangguan Sistem';

    final icon = isConn
        ? Icons.wifi_off_rounded
        : isTimeout
            ? Icons.timer_off_outlined
            : Icons.cloud_off_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.warningContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.warning, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: theme.warning),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            err.message,
            style: TextStyle(fontSize: 13, color: theme.textPrimary),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
              onPressed: _isSubmitting ? null : _processCheckout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsErrorBanner() {
    final theme = AppColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.errorRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.errorRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.errorRed),
          const SizedBox(width: 10),
          Expanded(child: Text(_optionsError!)),
          TextButton(
            onPressed: _isLoadingOptions ? null : _loadCouriersAndPayments,
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = _sortedItems;
    final cart = context.watch<CartProvider>();
    final theme = AppColors.of(context);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Checkout Pesanan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: cart.isLoading
          ? const Center(child: CircularProgressIndicator())
          : cart.errorMessage != null
              ? _buildCartUnavailable(
                  cart.errorMessage!,
                  () => cart.loadCart(),
                )
              : cart.items.isEmpty
                  ? _buildCartUnavailable(
                      'Keranjang belanja kosong. Tambahkan produk sebelum checkout.',
                      null,
                    )
                  : ResponsiveScrollWrapper(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    if (_conflictError != null) _buildConflictErrorBanner(),
                    if (_generalError != null) _buildGeneralErrorBanner(),
                    if (_optionsError != null) _buildOptionsErrorBanner(),

                  // ==========================================
                  // 1. DAFTAR BARANG CHECKOUT (MODEL LIST KE BAWAH)
                  // ==========================================
                  _buildSectionHeader(
                    title: 'Daftar Barang',
                    subtitle: 'Barang diurutkan ke bawah sesuai dengan jumlahnya',
                    actionWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.lightGreen,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: theme.borderColor),
                      ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${sortedItems.length} Produk',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryGreen,
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
      bottomNavigationBar: cart.isLoading || cart.errorMessage != null || cart.isEmpty
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildCartUnavailable(String message, VoidCallback? onRetry) {
    final theme = AppColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 56, color: theme.textSecondary),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba lagi'),
              ),
            ],
          ],
        ),
      ),
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
    final theme = AppColors.of(context);
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: theme.textSecondary),
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
    final theme = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.sort_rounded, size: 18, color: theme.primaryGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _sortAscending
                        ? 'Urutan: Jumlah Tersedikit (Naik ↑)'
                        : 'Urutan: Jumlah Terbanyak (Turun ↓)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: theme.textPrimary,
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
                color: theme.mutedContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _sortAscending ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 14,
                    color: theme.primaryGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ubah Urutan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryGreen,
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
    final theme = AppColors.of(context);
    final totalPerItem = item.harga * item.jumlah;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
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
              color: rank == 1 ? theme.primaryGreen : theme.mutedContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? theme.onPrimary : theme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Thumbnail / Icon Produk
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.lightGreen, theme.mutedContainer],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.eco, size: 26, color: theme.primaryGreen),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: theme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),

                // KOMPONEN 2: HARGA SATUAN
                Text(
                  '${_formatRupiah(item.harga)} / ${item.satuanJual}',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtotal harga item
                Text(
                  _formatRupiah(totalPerItem),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryGreen,
                  ),
                ),
              ],
            ),
          ),

          // KOMPONEN 3: JUMLAH BARANG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.mutedContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Jumlah',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.jumlah} ${item.satuanJual}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
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
    final theme = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.remove_shopping_cart_outlined,
              size: 40,
              color: theme.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tidak ada barang untuk di-checkout.',
              style: TextStyle(color: theme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final theme = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.lightGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: theme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Data Penerima & Alamat',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _namaCtrl,
            decoration: InputDecoration(
              labelText: 'Nama Penerima *',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: _serverErrors['nama_penerima'],
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Nama penerima wajib diisi.';
              }
              if (_serverErrors.containsKey('nama_penerima')) {
                return _serverErrors['nama_penerima'];
              }
              return null;
            },
            onChanged: (val) {
              _namaPenerima = val;
              if (_serverErrors.containsKey('nama_penerima')) {
                setState(() => _serverErrors.remove('nama_penerima'));
              }
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alamatCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Alamat Pengiriman *',
              prefixIcon: const Icon(Icons.location_on_outlined),
              errorText: _serverErrors['alamat_penerima'],
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Kolom alamat wajib diisi.';
              }
              if (_serverErrors.containsKey('alamat_penerima')) {
                return _serverErrors['alamat_penerima'];
              }
              return null;
            },
            onChanged: (val) {
              _alamatPenerima = val;
              if (_serverErrors.containsKey('alamat_penerima')) {
                setState(() => _serverErrors.remove('alamat_penerima'));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDateCard() {
    final theme = AppColors.of(context);
    final dateStr = '${_tanggalAntar.day.toString().padLeft(2, '0')}/${_tanggalAntar.month.toString().padLeft(2, '0')}/${_tanggalAntar.year}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.lightGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  color: theme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tanggal Antar',
                    style: TextStyle(fontSize: 12, color: theme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.primaryGreen,
              side: BorderSide(color: theme.primaryGreen),
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
    final theme = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
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
                      ? BorderSide(color: theme.borderColor.withValues(alpha: 0.5))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? theme.primaryGreen : theme.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      courier.nama,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: theme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    _formatRupiah(courier.tarif),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.primaryGreen : theme.textSecondary,
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
    final theme = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
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
                      ? BorderSide(color: theme.borderColor.withValues(alpha: 0.5))
                      : BorderSide.none,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? theme.primaryGreen : theme.textSecondary,
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
                            color: theme.textPrimary,
                          ),
                        ),
                        if (pm.deskripsi != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            pm.deskripsi!,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textSecondary,
                            ),
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
    final theme = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          _buildSummaryRow('Subtotal Produk', _formatRupiah(_calculatedSubtotal)),
          const SizedBox(height: 8),
          _buildSummaryRow('Ongkos Kirim (${_selectedCourier?.nama ?? '-'})', _formatRupiah(_ongkir)),
          Divider(height: 20, color: theme.borderColor.withValues(alpha: 0.5)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textPrimary,
                ),
              ),
              Text(
                _formatRupiah(_totalBayar),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    final theme = AppColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: theme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: theme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final theme = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: theme.softShadow,
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
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatRupiah(_totalBayar),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.primaryGreen,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: _isSubmitting ||
                            _isLoadingOptions ||
                            _selectedCourier == null ||
                            _selectedPayment == null
                        ? null
                        : _processCheckout,
                    child: _isSubmitting
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.onPrimary,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Buat Pesanan',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.onPrimary,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: theme.onPrimary,
                              ),
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
