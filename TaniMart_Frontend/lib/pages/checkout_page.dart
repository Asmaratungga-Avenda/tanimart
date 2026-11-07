import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../core/widgets/product_image.dart';
import '../models/cart_item.dart';
import '../models/courier.dart';
import '../models/payment_method.dart';
import '../services/api_service.dart';
import 'order_detail_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // --- form fields ---
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController(text: 'Budi Santoso');
  final _alamatController = TextEditingController();

  // --- data ---
  List<CartItem> _cartItems = [];
  List<Courier> _couriers = [];
  List<PaymentMethod> _paymentMethods = [];

  // --- selections ---
  Courier? _selectedCourier;
  PaymentMethod? _selectedPayment;
  DateTime _selectedDate = DateTime.now();

  // --- states ---
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _loadingError;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

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
        if (_paymentMethods.isNotEmpty) _selectedPayment = _paymentMethods.first;
        _isLoadingData = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingError = e.message;
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
    final minDate = _hasPerishable ? today : today;
    final maxDate = today.add(const Duration(days: 30));

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(today) ? today : _selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryGreen),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      if (_hasPerishable) {
        final isToday = picked.year == today.year &&
            picked.month == today.month &&
            picked.day == today.day;
        if (!isToday) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Produk mudah rusak hanya bisa dikirim hari ini (same-day delivery).'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          setState(() => _selectedDate = today);
          return;
        }
      }
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCourier == null || _selectedPayment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kurir dan metode pembayaran terlebih dahulu.'),
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
      if (!mounted) return;
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
          backgroundColor: Colors.red,
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
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: _primaryGreen))
          : _loadingError != null
              ? _buildError()
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                            '📦 Informasi Penerima', _buildRecipientForm()),
                        const SizedBox(height: 14),
                        _buildSection('🚚 Pilih Kurir', _buildCourierSelector()),
                        const SizedBox(height: 14),
                        _buildSection(
                            '📅 Tanggal Pengiriman', _buildDateSelector()),
                        const SizedBox(height: 14),
                        _buildSection(
                            '💳 Metode Pembayaran', _buildPaymentSelector()),
                        const SizedBox(height: 14),
                        _buildSection(
                            '🛒 Ringkasan Pesanan', _buildOrderSummary()),
                        const SizedBox(height: 20),
                        _buildTotalCard(),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: _isLoadingData || _loadingError != null
          ? null
          : _buildBottomBar(),
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              title,
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary),
            ),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(14), child: content),
        ],
      ),
    );
  }

  Widget _buildRecipientForm() {
    return Column(
      children: [
        TextFormField(
          controller: _namaController,
          decoration: InputDecoration(
            labelText: 'Nama Penerima',
            hintText: 'Masukkan nama lengkap',
            prefixIcon: const Icon(Icons.person_outline),
            labelStyle:
                GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
          validator: (v) =>
              (v?.trim().isEmpty ?? true) ? 'Nama penerima wajib diisi.' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _alamatController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Alamat Pengiriman',
            hintText: 'Jl. Merdeka No. 10, Kota, Provinsi',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 42),
              child: Icon(Icons.location_on_outlined),
            ),
            labelStyle:
                GoogleFonts.poppins(fontSize: 13, color: _textSecondary),
          ),
          style: GoogleFonts.poppins(fontSize: 14),
          validator: (v) => (v?.trim().isEmpty ?? true)
              ? 'Alamat pengiriman wajib diisi.'
              : null,
        ),
      ],
    );
  }

  Widget _buildCourierSelector() {
    if (_couriers.isEmpty) {
      return Text('Tidak ada kurir tersedia.',
          style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13));
    }
    return Column(
      children: _couriers
          .map(
            (c) => RadioListTile<Courier>(
              value: c,
              // ignore: deprecated_member_use
              groupValue: _selectedCourier,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _selectedCourier = val),
              activeColor: _primaryGreen,
              contentPadding: EdgeInsets.zero,
              title: Text(c.nama,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              subtitle: Text(_formatRupiah(c.tarif),
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: _primaryGreen)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
          .toList(),
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
            margin: const EdgeInsets.only(bottom: 10),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Keranjang berisi produk segar. Hanya bisa dikirim hari ini.',
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: _primaryGreen, size: 20),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE, d MMMM yyyy', 'id').format(_selectedDate),
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Hari Ini',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: _primaryGreen,
                            fontWeight: FontWeight.w600)),
                  ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSelector() {
    if (_paymentMethods.isEmpty) {
      return Text('Tidak ada metode pembayaran tersedia.',
          style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13));
    }
    return Column(
      children: _paymentMethods
          .map(
            (p) => RadioListTile<PaymentMethod>(
              value: p,
              // ignore: deprecated_member_use
              groupValue: _selectedPayment,
              // ignore: deprecated_member_use
              onChanged: (val) => setState(() => _selectedPayment = val),
              activeColor: _primaryGreen,
              contentPadding: EdgeInsets.zero,
              title: Text(p.nama,
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w500)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
          .toList(),
    );
  }

  Widget _buildOrderSummary() {
    if (_cartItems.isEmpty) {
      return Text('Keranjang kosong.',
          style: GoogleFonts.poppins(color: _textSecondary, fontSize: 13));
    }
    return Column(
      children: _cartItems
          .map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: ProductImage(
                          productName: item.nama,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.nama,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          Text(
                              '${_formatRupiah(item.harga)} × ${item.jumlah} ${item.satuanJual}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: _textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      _formatRupiah(item.harga * item.jumlah),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _primaryGreen),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  Widget _buildTotalCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _totalRow('Subtotal', _subtotal),
          const SizedBox(height: 6),
          _totalRow(
              'Ongkir (${_selectedCourier?.nama ?? '-'})', _ongkir),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Pembayaran',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(
                _formatRupiah(_total),
                style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _primaryGreen),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '* Total final dikonfirmasi oleh server saat proses checkout.',
            style: GoogleFonts.poppins(
                fontSize: 10,
                color: _textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _totalRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(fontSize: 13, color: _textSecondary)),
        Text(_formatRupiah(value),
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton.icon(
            onPressed: _isSubmitting ? null : _placeOrder,
            icon: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.shopping_bag_outlined),
            label: Text(
              _isSubmitting ? 'Memproses Pesanan...' : 'Buat Pesanan',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _primaryGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 12),
            Text(_loadingError!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: _textSecondary)),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadCheckoutData,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

