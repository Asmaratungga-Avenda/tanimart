import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/theme/theme_extension.dart';
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
  bool isPaying = false;

  String formatRupiah(int value) {
    final s = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return 'Rp $buffer';
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialOrder == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<OrderProvider>().loadOrderDetail(widget.orderId);
        }
      });
    }
  }

  OrderModel? _order(OrderProvider provider) {
    final loadedOrder = provider.orderDetail;
    if (loadedOrder?.id == widget.orderId) {
      return loadedOrder;
    }
    if (widget.initialOrder != null) {
      return widget.initialOrder;
    }
    return provider.orderDetail;
  }

  Future<void> _processPayment() async {
    final provider = context.read<OrderProvider>();
    final currentOrder = _order(provider);
    if (isPaying || currentOrder == null) return;

    final theme = AppColors.of(context);
    setState(() => isPaying = true);

    try {
      final success = await provider.confirmPayment(
        currentOrder.id,
        currentOrder.paymentMethodId,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.primaryGreen,
            behavior: SnackBarBehavior.floating,
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: theme.onPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Pembayaran berhasil diverifikasi oleh server!'),
                ),
              ],
            ),
          ),
        );
      } else {
        final error = provider.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.errorRed,
            behavior: SnackBarBehavior.floating,
            content: Text(error ?? 'Gagal memproses pembayaran.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: theme.errorRed,
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
      MaterialPageRoute(builder: (_) => const MainNavigationPage()),
      (route) => false,
    );
  }

  Color _getStatusColor(String status, AppColors theme) {
    switch (status.toLowerCase()) {
      case 'dibayar':
      case 'selesai':
        return theme.primaryGreen;
      case 'menunggu_pembayaran':
        return theme.warning;
      case 'diproses':
      case 'dikirim':
        return theme.info;
      case 'dibatalkan':
        return theme.errorRed;
      default:
        return theme.textSecondary;
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

  Widget _buildStatusTimeline(String status, AppColors theme) {
    final s = status.toLowerCase();
    final isPaid = s == 'dibayar' || s == 'diproses' || s == 'dikirim' || s == 'selesai';
    final isProcessing = s == 'diproses' || s == 'dikirim' || s == 'selesai';
    final isDone = s == 'selesai';

    Widget buildStep(String label, bool active, bool current, IconData icon) {
      final color = active
          ? theme.primaryGreen
          : current
              ? theme.warning
              : theme.borderColor;
      return Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active
                  ? theme.primaryGreen
                  : current
                      ? theme.warningContainer
                      : theme.mutedContainer,
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              active ? Icons.check : icon,
              size: 16,
              color: active ? theme.onPrimary : color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active || current ? FontWeight.bold : FontWeight.normal,
              color: active || current ? theme.textPrimary : theme.textSecondary,
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
          color: active ? theme.primaryGreen : theme.borderColor,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor),
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
    return Consumer<OrderProvider>(
      builder: (context, provider, child) {
        final order = _order(provider);
        final isLoading = provider.isLoading && widget.initialOrder == null;
        final errorMessage = provider.errorMessage;
        final theme = AppColors.of(context);

        return Scaffold(
          backgroundColor: theme.backgroundColor,
          appBar: AppBar(
            title: Text(order != null ? 'Pesanan #${order.id}' : 'Rincian Pesanan'),
            centerTitle: true,
            backgroundColor: theme.surfaceColor,
            foregroundColor: theme.textPrimary,
          ),
          body: ResponsiveScrollWrapper(
            child: _buildBody(provider, order, isLoading, errorMessage),
          ),
          bottomNavigationBar: order != null && !isLoading
              ? _buildBottomBar(order)
              : null,
        );
      },
    );
  }

  Widget _buildBody(OrderProvider provider, OrderModel? o, bool isLoading, String? errorMessage) {
    final theme = AppColors.of(context);
    if (isLoading && o == null) {
      return Center(
        child: CircularProgressIndicator(color: theme.primaryGreen),
      );
    }

    if (o == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 64,
                color: theme.textSecondary,
              ),
              const SizedBox(height: 16),
              const Text('Pesanan Tidak Ditemukan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(errorMessage ?? 'Pesanan tidak ditemukan pada sistem.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: theme.primaryGreen),
                onPressed: backToCatalog,
                child: const Text('Kembali ke Katalog Utama'),
              ),
            ],
          ),
        ),
      );
    }

    return _buildOrderDetailContent(o);
  }

  Widget _buildOrderDetailContent(OrderModel o) {
    final theme = AppColors.of(context);
    final statusColor = _getStatusColor(o.status, theme);
    final statusLabel = _getStatusLabel(o.status);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        // Timeline Progres Status Transaksi
        _buildStatusTimeline(o.status, theme),
        const SizedBox(height: 12),

        // Status Pesanan Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                      ),
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
                        style: TextStyle(fontSize: 11, color: theme.textSecondary),
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
        Text(
          'Daftar Produk yang Dibeli',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(14),
            itemCount: o.items.length,
            separatorBuilder: (_, _) => Divider(
              height: 20,
              color: theme.borderColor.withValues(alpha: 0.5),
            ),
            itemBuilder: (context, index) {
              final item = o.items[index];
              final productName = item.product?.nama ?? item.namaProduk;
              final satuan = item.product?.satuanJual ?? 'unit';

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.lightGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.eco,
                      color: theme.primaryGreen,
                      size: 22,
                    ),
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
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatRupiah(item.subtotal),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Informasi Pengiriman
        Text(
          'Informasi Pengiriman',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
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
        Text(
          'Rincian Pembayaran',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.borderColor),
          ),
          child: Column(
            children: [
              _buildSummaryRow('Subtotal Produk', formatRupiah(o.subtotal)),
              const SizedBox(height: 8),
              _buildSummaryRow('Ongkos Kirim', formatRupiah(o.ongkir)),
              Divider(
                height: 20,
                color: theme.borderColor.withValues(alpha: 0.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Tagihan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                    ),
                  ),
                  Text(
                    formatRupiah(o.totalHarga),
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
        ),
      ],
    );
  }

  Widget _buildRowInfo(String label, String value) {
    final theme = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: theme.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: theme.textPrimary,
            ),
          ),
        ),
      ],
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

  Widget _buildBottomBar(OrderModel o) {
    final isUnpaid = o.status == 'menunggu_pembayaran';
    final theme = AppColors.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor,
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
                          backgroundColor: theme.primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: isPaying
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: theme.onPrimary,
                                ),
                              )
                            : const Icon(Icons.payment_rounded),
                        label: Text(
                          isPaying
                              ? 'Mengonfirmasi Pembayaran...'
                              : 'Konfirmasi Pembayaran',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: isPaying ? null : _processPayment,
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
                        foregroundColor: theme.primaryGreen,
                        side: BorderSide(color: theme.primaryGreen),
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
