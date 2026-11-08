import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';
import '../main.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const OrderDetailPage({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  // 4 Keadaan Layar wajib
  KeadaanMuat state = KeadaanMuat.memuat;
  OrderModel? order;
  ApiException? lastError;

  bool isPaying = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder != null) {
      order = widget.initialOrder;
      state = KeadaanMuat.berhasil;
    } else {
      loadOrderDetail();
    }
  }

  String formatRupiah(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  Future<void> loadOrderDetail() async {
    setState(() {
      state = KeadaanMuat.memuat;
      lastError = null;
    });

    try {
      final res = await ApiService.getOrder(widget.orderId);
      if (!mounted) return;
      setState(() {
        order = res;
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
          message: 'Gagal memuat rincian pesanan dari server.',
          errorType: ApiErrorType.other,
        );
        state = KeadaanMuat.galat;
      });
    }
  }

  /// Simulasi pembayaran nyata melalui PATCH /api/pesanan/{id}/status ke backend
  /// Bukan sekadar mengubah tampilan saja (Kriteria 7 Butir 7)
  Future<void> simulatePayment() async {
    if (isPaying || order == null) return;

    setState(() => isPaying = true);

    try {
      final updated = await ApiService.updateOrderStatus(order!.id, 'dibayar');
      if (!mounted) return;

      setState(() {
        order = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Pembayaran berhasil diverifikasi oleh server!'),
              ),
            ],
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade800,
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
            content: Text('Terjadi gangguan jaringan saat memproses pembayaran.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isPaying = false);
    }
  }

  /// Kembali ke katalog dengan tumpukan halaman dibersihkan (Kriteria Perpindahan)
  void backToCatalog() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainFocusedPage(initialIndex: 0)),
      (route) => false,
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dibayar':
      case 'selesai':
        return const Color(0xFF2E7D32);
      case 'menunggu_pembayaran':
        return Colors.orange.shade800;
      case 'diproses':
      case 'dikirim':
        return Colors.blue.shade700;
      case 'dibatalkan':
        return Colors.red.shade700;
      default:
        return const Color(0xFF64748B);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'dibayar':
        return 'Sudah Dibayar';
      case 'diproses':
        return 'Sedang Dipersiapkan Petani';
      case 'dikirim':
        return 'Dalam Pengiriman';
      case 'selesai':
        return 'Pesanan Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Widget _buildStatusTimeline(String status) {
    final s = status.toLowerCase();
    final isPaid = s == 'dibayar' || s == 'diproses' || s == 'dikirim' || s == 'selesai';
    final isProcessing = s == 'diproses' || s == 'dikirim' || s == 'selesai';
    final isDone = s == 'selesai';

    Widget buildStep(String label, bool active, bool current, IconData icon) {
      final color = active ? const Color(0xFF2E7D32) : (current ? Colors.orange.shade800 : const Color(0xFFCBD5E1));
      return Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF2E7D32) : (current ? Colors.orange.shade50 : const Color(0xFFF1F5F9)),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              active ? Icons.check : icon,
              size: 16,
              color: active ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active || current ? FontWeight.bold : FontWeight.normal,
              color: active || current ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
    }

    Widget buildLine(bool active) {
      return Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 16),
          color: active ? const Color(0xFF2E7D32) : const Color(0xFFE2E8F0),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildStep('Pesan', true, false, Icons.receipt_outlined),
          buildLine(isPaid),
          buildStep('Bayar', isPaid, s == 'menunggu_pembayaran', Icons.payment_outlined),
          buildLine(isProcessing),
          buildStep('Proses', isProcessing, s == 'dibayar', Icons.agriculture_outlined),
          buildLine(isDone),
          buildStep('Tiba', isDone, s == 'dikirim', Icons.check_circle_outline),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),
      appBar: AppBar(
        title: Text(order != null ? 'Pesanan #${order!.id}' : 'Rincian Pesanan'),
        centerTitle: true,
      ),
      body: ResponsiveScrollWrapper(
        child: _buildBody(),
      ),
      bottomNavigationBar: state == KeadaanMuat.berhasil && order != null
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
              Text('Memuat rincian transaksi pesanan...'),
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
                const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFF64748B)),
                const SizedBox(height: 16),
                const Text('Pesanan Tidak Ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Nomor pesanan yang Anda cari tidak ada pada sistem.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: backToCatalog,
                  child: const Text('Kembali ke Katalog Utama'),
                ),
              ],
            ),
          ),
        );

      case KeadaanMuat.galat:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                const Text('Gagal Memuat Pesanan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(lastError?.message ?? 'Terjadi kesalahan sistem.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: loadOrderDetail,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        );

      case KeadaanMuat.berhasil:
        final o = order!;
        final statusColor = _getStatusColor(o.status);
        final statusLabel = _getStatusLabel(o.status);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            // Timeline Progres Status Transaksi
            _buildStatusTimeline(o.status),
            const SizedBox(height: 12),

            // Status Pesanan Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      o.status == 'dibayar' ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                      color: statusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan #${o.id}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        if (o.createdAt != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Waktu: ${o.createdAt!.substring(0, 16).replaceAll('T', ' ')}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Item-item Pembelian
            const Text(
              'Daftar Produk yang Dibeli',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(14),
                itemCount: o.items.length,
                separatorBuilder: (_, _) => const Divider(height: 20, color: Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final item = o.items[index];
                  final productName = item.product?.nama ?? 'Produk Pertanian #${item.productId}';
                  final satuan = item.product?.satuanJual ?? 'unit';

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.eco, color: Color(0xFF2E7D32), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.quantity} $satuan × ${formatRupiah(item.hargaSatuan)}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatRupiah(item.subtotal),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // Informasi Pengiriman
            const Text(
              'Informasi Pengiriman',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildRowInfo('Penerima', o.namaPenerima),
                  const SizedBox(height: 8),
                  _buildRowInfo('Alamat Tujuan', o.alamatPenerima),
                  const SizedBox(height: 8),
                  _buildRowInfo('Tanggal Antar', o.tanggalAntar),
                  const SizedBox(height: 8),
                  _buildRowInfo('Jasa Kurir', o.courier?.nama ?? 'Kurir #${o.kurirId}'),
                  const SizedBox(height: 8),
                  _buildRowInfo('Metode Pembayaran', o.paymentMethod?.nama ?? 'Metode #${o.paymentMethodId}'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Rincian Biaya
            const Text(
              'Rincian Pembayaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal Produk', formatRupiah(o.subtotal)),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Ongkos Kirim', formatRupiah(o.ongkir)),
                  const Divider(height: 20, color: Color(0xFFF1F5F9)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                      ),
                      Text(
                        formatRupiah(o.totalHarga),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildRowInfo(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ),
      ],
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
    final o = order!;
    final isUnpaid = o.status == 'menunggu_pembayaran';

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isUnpaid) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: isPaying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.payment_rounded),
                        label: Text(
                          isPaying ? 'Memproses Pembayaran...' : 'Bayar Sekarang (Simulasi)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isPaying ? null : simulatePayment,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Tombol Kembali ke Katalog dengan tumpukan halaman dibersihkan
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Kembali ke Katalog Utama'),
                      onPressed: backToCatalog,
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

