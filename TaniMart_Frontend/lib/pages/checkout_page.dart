import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/product_image.dart';
import '../models/cart_item.dart';
import '../models/courier.dart';
import '../models/payment_method.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'order_detail_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // --- Form Controllers ---
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController(text: 'Budi Santoso');
  final _teleponController = TextEditingController(text: '081234567890');
  final _alamatController = TextEditingController(
      text: 'Jl. Pertanian Raya No. 45, Kebon Jeruk, Jakarta Barat');
  final _catatanController = TextEditingController();

  // --- Data ---
  List<CartItem> _cartItems = [];
  List<Courier> _couriers = [];
  List<PaymentMethod> _paymentMethods = [];

  // --- Selections ---
  Courier? _selectedCourier;
  PaymentMethod? _selectedPayment;
  DateTime _selectedDate = DateTime.now();

  // --- States ---
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _loadingError;
  bool _isItemsExpanded = true;

  static const _primaryGreen = AppTheme.primaryGreen;
  static const _lightGreen = AppTheme.lightGreen;
  static const _textPrimary = AppTheme.textPrimary;
  static const _textSecondary = AppTheme.textSecondary;
  static const _accentOrange = AppTheme.accentOrange;

  @override
  void initState() {
    super.initState();
    _loadCheckoutData();
  }

  Future<void> _loadCheckoutData() async {
    setState(() {
      _isLoadingData = true;
      _loadingError = null;
    });
    try {
      final results = await Future.wait([
        ApiService.getCart(),
        ApiService.getCouriers(),
        ApiService.getPaymentMethods(),
      ]);
      if (!mounted) return;
      final cartResp = results[0] as CartResponse;
      setState(() {
        _cartItems = cartResp.items;
        _couriers = results[1] as List<Courier>;
        _paymentMethods = results[2] as List<PaymentMethod>;
        if (_couriers.isNotEmpty) _selectedCourier = _couriers.first;
        if (_paymentMethods.isNotEmpty) {
          _selectedPayment = _paymentMethods.first;
        }
        _isLoadingData = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = e.message;
        _isLoadingData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingError = 'Gagal memuat data checkout dari server.';
        _isLoadingData = false;
      });
    }
  }

  int get _subtotal =>
      _cartItems.fold(0, (sum, item) => sum + item.harga * item.jumlah);
  int get _ongkir => _selectedCourier?.tarif ?? 0;
  int get _total => _subtotal + _ongkir;

  String _formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  bool get _hasPerishable => _cartItems.any((i) => i.mudahRusak);

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final maxDate = today.add(const Duration(days: 30));

    if (_hasPerishable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Produk segar wajib same-day delivery (pengiriman hari ini).',
                ),
              ),
            ],
          ),
          backgroundColor: _accentOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: today,
      lastDate: maxDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _primaryGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lengkapi informasi penerima yang bertanda bintang (*).'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedCourier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kurir pengiriman terlebih dahulu.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih metode pembayaran terlebih dahulu.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keranjang belanja masih kosong.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'nama_penerima': _namaController.text.trim(),
      'alamat_penerima': _alamatController.text.trim(),
      'kurir_id': _selectedCourier!.id,
      'payment_method_id': _selectedPayment!.id,
      'tanggal_antar': DateFormat('yyyy-MM-dd').format(_selectedDate),
      'items': _cartItems
          .map((item) => {
                'product_id': item.produkId,
                'quantity': item.jumlah,
              })
          .toList(),
    };

    try {
      final order = await ApiService.checkout(payload);

      // ─── PENAMBAHAN NOTIFIKASI LANGSUNG SECARA REAKTIF ───
      // Seketika menambah badge notifikasi tanpa reload
      NotificationService.addOrderNotification(order);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pesanan #${order.id} berhasil dibuat! Notifikasi langsung bertambah.',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: _primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );

      // Navigasi ke detail pesanan
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailPage(
            orderId: order.id,
            order: order,
            fromCheckout: true,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    _alamatController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          'Checkout Pesanan',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoadingData
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryGreen),
                  SizedBox(height: 14),
                  Text('Menyiapkan data checkout...',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : _loadingError != null
              ? _buildErrorState()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Progress / Step Info
                        _buildStepIndicator(),
                        const SizedBox(height: 16),

                        // 1. Alamat Pengiriman
                        _buildSectionCard(
                          icon: Icons.location_on_rounded,
                          iconColor: _primaryGreen,
                          title: 'Alamat Pengiriman',
                          subtitle: 'Pastikan tujuan pengiriman sudah sesuai',
                          content: _buildRecipientForm(),
                        ),
                        const SizedBox(height: 14),

                        // 2. Metode & Kurir Pengiriman
                        _buildSectionCard(
                          icon: Icons.local_shipping_rounded,
                          iconColor: const Color(0xFF1565C0),
                          title: 'Pilihan Kurir & Tarif',
                          subtitle: 'Kurir khusus armada AgriMart Express',
                          content: _buildCourierSelector(),
                        ),
                        const SizedBox(height: 14),

                        // 3. Jadwal Pengiriman
                        _buildSectionCard(
                          icon: Icons.event_available_rounded,
                          iconColor: _accentOrange,
                          title: 'Jadwal Pengiriman',
                          subtitle: 'Pilih waktu tiba pesanan di lokasi Anda',
                          content: _buildDateSelector(),
                        ),
                        const SizedBox(height: 14),

                        // 4. Metode Pembayaran
                        _buildSectionCard(
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: const Color(0xFF7B1FA2),
                          title: 'Metode Pembayaran',
                          subtitle: 'Pilih opsi pembayaran yang Anda inginkan',
                          content: _buildPaymentSelector(),
                        ),
                        const SizedBox(height: 14),

                        // 5. Ringkasan Produk
                        _buildSectionCard(
                          icon: Icons.shopping_basket_rounded,
                          iconColor: _primaryGreen,
                          title: 'Ringkasan Produk (${_cartItems.length} item)',
                          subtitle: 'Daftar produk yang akan dikirim',
                          trailing: IconButton(
                            icon: Icon(
                              _isItemsExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: _textSecondary,
                            ),
                            onPressed: () => setState(
                                () => _isItemsExpanded = !_isItemsExpanded),
                          ),
                          content: _buildOrderSummary(),
                        ),
                        const SizedBox(height: 14),

                        // 6. Rincian Pembayaran
                        _buildPriceBreakdownCard(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _isLoadingData || _loadingError != null
          ? null
          : _buildStickyBottomBar(),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _lightGreen,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primaryGreen.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: _primaryGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined,
                color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Transaksi Aman & Bergaransi Segar dari Mitra Petani AgriMart',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: _primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget content,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: _textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Penerima *',
                  hintText: 'Nama lengkap',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  labelStyle: GoogleFonts.poppins(fontSize: 12.5),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 13.5),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Nama penerima wajib diisi.'
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: _teleponController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'No. WhatsApp / HP *',
                  hintText: '08xxxxxxx',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  labelStyle: GoogleFonts.poppins(fontSize: 12.5),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                style: GoogleFonts.poppins(fontSize: 13.5),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Nomor HP wajib diisi.'
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _alamatController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Alamat Lengkap Pengiriman *',
            hintText: 'Nama jalan, nomor rumah, RT/RW, kelurahan, kecamatan',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.home_outlined, size: 20),
            ),
            labelStyle: GoogleFonts.poppins(fontSize: 12.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: GoogleFonts.poppins(fontSize: 13.5),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Alamat pengiriman wajib diisi.'
              : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _catatanController,
          decoration: InputDecoration(
            labelText: 'Catatan untuk Kurir (Opsional)',
            hintText: 'Contoh: Titipkan ke satpam / pagar warna hitam',
            prefixIcon: const Icon(Icons.sticky_note_2_outlined, size: 20),
            labelStyle: GoogleFonts.poppins(fontSize: 12.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
      ],
    );
  }

  Widget _buildCourierSelector() {
    if (_couriers.isEmpty) {
      return Text(
        'Belum ada pilihan kurir aktif.',
        style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13),
      );
    }
    return Column(
      children: _couriers.map((c) {
        final isSelected = _selectedCourier?.id == c.id;
        final isCloseArea = c.tarif <= 10000;

        return InkWell(
          onTap: () => setState(() => _selectedCourier = c),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _primaryGreen : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryGreen.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCloseArea
                        ? Icons.two_wheeler_rounded
                        : Icons.local_shipping_rounded,
                    color: isSelected ? _primaryGreen : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.nama,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isCloseArea
                            ? 'Same-day delivery (Estimasi 2-4 jam)'
                            : 'Reguler delivery (Jangkauan area luas)',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? _primaryGreen : _lightGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _formatRupiah(c.tarif),
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : _primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateSelector() {
    final today = DateTime.now();
    final isToday = _selectedDate.year == today.year &&
        _selectedDate.month == today.month &&
        _selectedDate.day == today.day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_hasPerishable)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.eco_rounded, color: _accentOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Keranjang berisi produk mudah rusak. Pengiriman otomatis diprioritaskan hari ini (Same-day).',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _lightGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: _primaryGreen, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tanggal Pengantaran',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id').format(_selectedDate),
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Hari Ini',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: _primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded,
                      size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelector() {
    if (_paymentMethods.isEmpty) {
      return Text(
        'Belum ada metode pembayaran tersedia.',
        style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13),
      );
    }
    return Column(
      children: _paymentMethods.map((p) {
        final isSelected = _selectedPayment?.id == p.id;
        final isTransfer = p.nama.toLowerCase().contains('transfer');

        return InkWell(
          onTap: () => setState(() => _selectedPayment = p),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? _primaryGreen : const Color(0xFFE5E7EB),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _primaryGreen.withValues(alpha: 0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isTransfer
                        ? Icons.account_balance_rounded
                        : Icons.payments_outlined,
                    color: isSelected ? _primaryGreen : Colors.grey.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.nama,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.deskripsi ??
                            (isTransfer
                                ? 'Transfer bank otomatis & verifikasi instan'
                                : 'Bayar tunai ke kurir saat barang diterima'),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _primaryGreen : Colors.grey.shade400,
                      width: 2,
                    ),
                    color: isSelected ? _primaryGreen : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrderSummary() {
    if (_cartItems.isEmpty) {
      return Text('Keranjang belanja kosong.',
          style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13));
    }

    if (!_isItemsExpanded) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_cartItems.length} macam produk dipilih',
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
          Text(
            _formatRupiah(_subtotal),
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primaryGreen,
            ),
          ),
        ],
      );
    }

    return Column(
      children: _cartItems.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: ProductImage(
                    productName: item.nama,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nama,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${_formatRupiah(item.harga)} × ${item.jumlah} ${item.satuanJual}',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: _textSecondary,
                          ),
                        ),
                        if (item.mudahRusak) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Segar',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _accentOrange,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatRupiah(item.harga * item.jumlah),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPriceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _breakdownRow('Subtotal Produk', _formatRupiah(_subtotal)),
          const SizedBox(height: 8),
          _breakdownRow(
            'Ongkir (${_selectedCourier?.nama ?? 'Pilih kurir'})',
            _selectedCourier != null ? _formatRupiah(_ongkir) : 'Rp 0',
          ),
          const SizedBox(height: 8),
          _breakdownRow(
            'Biaya Layanan & Penanganan',
            'GRATIS',
            valueColor: _primaryGreen,
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Tagihan',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              Text(
                _formatRupiah(_total),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12.5, color: _textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor ?? _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Tagihan',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: _textSecondary,
                    ),
                  ),
                  Text(
                    _formatRupiah(_total),
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _placeOrder,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline_rounded,
                          size: 19),
                  label: Text(
                    _isSubmitting ? 'Memproses...' : 'Buat Pesanan',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 54, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              _loadingError ?? 'Gagal memuat data checkout.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadCheckoutData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(
                backgroundColor: _primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
