import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Order> _orders = [];
  bool _isLoading = true;
  String? _error;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await ApiService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = result;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F6),
      appBar: AppBar(
        backgroundColor: _primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Pesanan Saya',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
            tooltip: 'Muat Ulang',
          ),
        ],
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
              const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: _textSecondary)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadOrders,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }
    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 70)),
            const SizedBox(height: 14),
            Text('Belum ada pesanan',
                style: GoogleFonts.poppins(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: _textPrimary)),
            const SizedBox(height: 6),
            Text('Mulai belanja untuk membuat pesanan pertamamu!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                    fontSize: 13, color: _textSecondary)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: _primaryGreen,
      onRefresh: _loadOrders,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _orders.length,
        itemBuilder: (ctx, i) => _OrderCard(
          order: _orders[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  OrderDetailPage(orderId: _orders[i].id, order: _orders[i]),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;

  static const _primaryGreen = Color(0xFF2E7D32);
  static const _textPrimary = Color(0xFF1F2937);
  static const _textSecondary = Color(0xFF6B7280);

  const _OrderCard({required this.order, required this.onTap});

  String _formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    final statusInfo = _statusInfo(order.status);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.055),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: _primaryGreen, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan #${order.id}',
                          style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary),
                        ),
                        if (order.createdAt != null)
                          Text(
                            _formatDate(order.createdAt!),
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: _textSecondary),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusInfo['bgColor'] as Color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusInfo['label'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusInfo['color'] as Color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (order.items.isNotEmpty) ...[
                    Text(
                      order.items
                          .take(2)
                          .map((i) => '${i.namaProduk} ×${i.quantity}')
                          .join(', '),
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: _textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (order.items.length > 2)
                      Text(
                        '+ ${order.items.length - 2} produk lainnya',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.grey),
                      ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      if (order.namaCourier != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.local_shipping_outlined,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(order.namaCourier!,
                                style: GoogleFonts.poppins(
                                    fontSize: 12, color: _textSecondary)),
                          ],
                        ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total',
                              style: GoogleFonts.poppins(
                                  fontSize: 11, color: _textSecondary)),
                          Text(
                            _formatRupiah(order.totalHarga),
                            style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: _primaryGreen),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: Text('Lihat Detail',
                          style: GoogleFonts.poppins(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primaryGreen,
                        side: const BorderSide(color: _primaryGreen),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return '${dt.day} ${months[dt.month]} ${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'menunggu_pembayaran':
        return {
          'label': 'Menunggu Bayar',
          'color': Colors.orange.shade800,
          'bgColor': Colors.orange.shade50,
        };
      case 'dibayar':
        return {
          'label': 'Dibayar',
          'color': Colors.blue.shade700,
          'bgColor': Colors.blue.shade50,
        };
      case 'diproses':
        return {
          'label': 'Diproses',
          'color': Colors.purple.shade700,
          'bgColor': Colors.purple.shade50,
        };
      case 'dikirim':
        return {
          'label': 'Dikirim',
          'color': Colors.indigo.shade700,
          'bgColor': Colors.indigo.shade50,
        };
      case 'selesai':
        return {
          'label': 'Selesai',
          'color': const Color(0xFF2E7D32),
          'bgColor': const Color(0xFFE8F5E9),
        };
      case 'dibatalkan':
        return {
          'label': 'Dibatalkan',
          'color': Colors.red.shade700,
          'bgColor': Colors.red.shade50,
        };
      default:
        return {
          'label': status,
          'color': Colors.grey.shade700,
          'bgColor': Colors.grey.shade100,
        };
    }
  }
}

