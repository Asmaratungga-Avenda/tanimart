import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  final Order? order;
  final bool fromCheckout;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.order,
    this.fromCheckout = false,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _isLoading = false;
  String? _error;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _lightGreen = Color(0xFFE8F5E9);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

  final List<String> _statusSteps = [
    'menunggu_pembayaran',
    'dibayar',
    'diproses',
    'dikirim',
    'selesai',
  ];
  final List<String> _statusLabels = [
    'Menunggu\nPembayaran',
    'Dibayar',
    'Diproses',
    'Dikirim',
    'Selesai',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _order = widget.order;
    } else {
      _fetchOrder();
    }
  }

  Future<void> _fetchOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getOrderDetail(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = result;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  String _formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '',
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}, ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  int get _currentStep {
    final order = _order;
    if (order == null) return 0;
    if (order.status == 'dibatalkan') return -1;
    final idx = _statusSteps.indexOf(order.status);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Detail Pesanan',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: widget.fromCheckout
            ? IconButton(
                icon: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: _primaryGreen));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: _textSecondary)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _fetchOrder,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    final order = _order;
    if (order == null) {
      return const Center(child: Text('Data pesanan tidak tersedia.'));
    }

    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _fetchOrder,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.fromCheckout) _buildSuccessHeader(),
            _buildStatusProgress(order),
            const SizedBox(height: 14),
            _buildInfoCard(order),
            const SizedBox(height: 14),
            _buildItemsCard(order),
            const SizedBox(height: 14),
            _buildPaymentCard(order),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 50),
          const SizedBox(height: 10),
          Text(
            'Pesanan Berhasil Dibuat! 🎉',
            style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Terima kasih telah berbelanja di AgriMart.',
            style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusProgress(Order order) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Pesanan #${order.id}',
                style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary),
              ),
              const Spacer(),
              if (order.status == 'dibatalkan')
                _statusBadge('Dibatalkan', Colors.red.shade700,
                    Colors.red.shade50)
              else
                _statusBadge(
                  _statusLabels[_currentStep >= 0 ? _currentStep : 0]
                      .replaceAll('\n', ' '),
                  _primaryGreen,
                  _lightGreen,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (order.status != 'dibatalkan') ...[
            SizedBox(
              height: 80,
              child: Row(
                children: List.generate(_statusSteps.length, (i) {
                  final isDone = i <= _currentStep;
                  final isActive = i == _currentStep;
                  return Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (i > 0)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: isDone
                                      ? _primaryGreen
                                      : Colors.grey.shade300,
                                ),
                              ),
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? _primaryGreen
                                    : Colors.grey.shade300,
                                border: isActive
                                    ? Border.all(
                                        color: _primaryGreen, width: 2)
                                    : null,
                              ),
                              child: isDone
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                            if (i < _statusSteps.length - 1)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: i < _currentStep
                                      ? _primaryGreen
                                      : Colors.grey.shade300,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _statusLabels[i],
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isDone ? _primaryGreen : _textSecondary,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
          if (order.tanggalAntar.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Tanggal Antar: ${order.tanggalAntar}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: _textSecondary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: GoogleFonts.poppins(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildInfoCard(Order order) {
    return _card(
      '📍 Informasi Pengiriman',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.person_outline, 'Penerima', order.namaPenerima),
          const SizedBox(height: 8),
          _infoRow(Icons.location_on_outlined, 'Alamat', order.alamatPenerima),
          const SizedBox(height: 8),
          _infoRow(Icons.local_shipping_outlined, 'Kurir',
              order.namaCourier ?? 'Kurir #${order.kurirId}'),
          const SizedBox(height: 8),
          _infoRow(Icons.event, 'Tanggal Antar', order.tanggalAntar),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: _primaryGreen),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: _textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary)),
        ),
      ],
    );
  }

  Widget _buildItemsCard(Order order) {
    return _card(
      '🛒 Produk yang Dipesan',
      Column(
        children: [
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                          child:
                              Text('🌿', style: TextStyle(fontSize: 22))),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.namaProduk,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _textPrimary)),
                          Text(
                              '${_formatRupiah(item.hargaSatuan)} × ${item.quantity}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: _textSecondary)),
                        ],
                      ),
                    ),
                    Text(_formatRupiah(item.subtotal),
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primaryGreen)),
                  ],
                ),
              )),
          const Divider(height: 20),
          _summaryRow('Subtotal', _formatRupiah(order.subtotal)),
          const SizedBox(height: 4),
          _summaryRow(
              'Ongkir (${order.namaCourier ?? '-'})',
              _formatRupiah(order.ongkir)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              Text(_formatRupiah(order.totalHarga),
                  style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryGreen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.poppins(
                fontSize: 13, color: _textSecondary)),
        Text(value,
            style: GoogleFonts.poppins(
                fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildPaymentCard(Order order) {
    return _card(
      '💳 Informasi Pembayaran',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(Icons.payment_outlined, 'Metode',
              order.namaPaymentMethod ?? 'Metode #${order.paymentMethodId}'),
          if (order.createdAt != null) ...[
            const SizedBox(height: 8),
            _infoRow(Icons.access_time, 'Waktu Pesan',
                _formatDate(order.createdAt)),
          ],
        ],
      ),
    );
  }

  Widget _card(String title, Widget content) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _textPrimary)),
          ),
          const Divider(height: 1),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }
}

