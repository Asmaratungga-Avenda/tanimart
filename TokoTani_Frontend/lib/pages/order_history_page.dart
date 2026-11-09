import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/theme/theme_extension.dart';
import '../widgets/responsive_wrapper.dart';
import 'product_catalog_page.dart';
import 'order_detail_page.dart';

class OrderHistoryPage extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onGoToCatalog;

  const OrderHistoryPage({
    super.key,
    this.showBackButton = false,
    this.onGoToCatalog,
  });

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().loadOrders();
    });
  }

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
        return 'Diproses Petani';
      case 'dikirim':
        return 'Dalam Pengiriman';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppColors.of(context);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        centerTitle: true,
        backgroundColor: theme.surfaceColor,
        foregroundColor: theme.textPrimary,
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan Riwayat',
            onPressed: () => context.read<OrderProvider>().loadOrders(),
          ),
        ],
      ),
      body: ResponsiveScrollWrapper(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders;

    if (provider.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat riwayat pesanan...'),
          ],
        ),
      );
    }

    if (provider.isEmpty) {
      if (provider.errorMessage != null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.of(context).errorRed,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Gagal Memuat Pesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage ?? 'Terjadi kesalahan sistem.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.of(context).primaryGreen,
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba Lagi'),
                  onPressed: () => provider.loadOrders(),
                ),
              ],
            ),
          ),
        );
      }

      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.of(context).lightGreen,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.of(context).primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Pesanan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.of(context).textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anda belum memiliki riwayat transaksi produk pertanian segar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.of(context).textSecondary),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.of(context).primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Mulai Belanja Sekarang'),
                onPressed: () {
                  if (widget.onGoToCatalog != null) {
                    widget.onGoToCatalog!();
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProductCatalogPage(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadOrders(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: orders.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = orders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    final theme = AppColors.of(context);
    final statusColor = _getStatusColor(order.status, theme);
    final statusLabel = _getStatusLabel(order.status);

    return InkWell(
      onTap: () async {
        final orderId = order.id;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: orderId)),
        );
        if (mounted) {
          context.read<OrderProvider>().loadOrders();
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Nomor Pesanan & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.receipt_outlined,
                      size: 16,
                      color: theme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#TRX-${order.id}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            Divider(
              height: 20,
              color: theme.borderColor.withValues(alpha: 0.5),
            ),

            // Ringkasan Isi Pesanan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.lightGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: theme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.items.isNotEmpty
                            ? order.items.first.namaProduk
                            : 'Pesanan Produk Tani',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.items.length > 1
                            ? '${order.items.first.quantity} item + ${order.items.length - 1} produk lainnya'
                            : (order.items.isNotEmpty
                                  ? '${order.items.first.quantity} item'
                                  : 'Penerima: ${order.namaPenerima}'),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textSecondary,
                        ),
                      ),
                      if (order.tanggalAntar.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Jadwal antar: ${order.tanggalAntar}',
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
            const SizedBox(height: 12),

            // Baris Bawah: Total Pembayaran & Tombol Lihat Detail
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.textSecondary,
                      ),
                    ),
                    Text(
                      formatRupiah(order.totalHarga),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rincian',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryGreen,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: theme.primaryGreen,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
