import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/widgets/product_image.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  final OrderModel? initialOrder;

  const OrderDetailPage({super.key, required this.orderId, this.initialOrder});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
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

  String _rupiah(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi';
      case 'dibayar':
        return 'Dibayar';
      case 'diproses':
        return 'Diproses';
      case 'dikirim':
        return 'Dikirim';
      case 'tiba':
        return 'Tiba';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'dibayar':
      case 'selesai':
        return Colors.green;
      case 'menunggu_pembayaran':
      case 'menunggu_konfirmasi':
      case 'diproses':
        return Colors.orange;
      case 'dikirim':
      case 'tiba':
        return Colors.blue;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final provider = context.watch<OrderProvider>();
    final order = provider.orderDetail ?? widget.initialOrder;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: order == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.nomorPesanan,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(
                            order.createdAt.toString().substring(0, 16),
                            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(order.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(order.status),
                          style: TextStyle(
                            color: _getStatusColor(order.status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTimeline(order, colors),
                  const SizedBox(height: 32),
                  const Text('Produk Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  ...order.items.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ProductImage(
                                imageUrl: item.fotoProduk,
                                productName: item.namaProduk,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.namaProduk, style: const TextStyle(fontWeight: FontWeight.w500)),
                                  Text('${item.jumlah} x Rp ${_rupiah(item.hargaSatuan)}',
                                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              'Rp ${_rupiah(item.hargaSatuan * item.jumlah)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 32),
                  const Text('Ringkasan Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  _summaryRow('Subtotal', 'Rp ${_rupiah(order.totalHarga)}'),
                  _summaryRow('Ongkir', 'Rp ${_rupiah(8000)}'), // Placeholder as per reference
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        'Rp ${_rupiah(order.totalHarga + 8000)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (order.status.toLowerCase() == 'tiba')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => provider.completeOrder(order.id),
                        child: const Text('Pesanan Selesai'),
                      ),
                    ),
                  if (order.status.toLowerCase() == 'menunggu_pembayaran')
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final ok = await provider.confirmPayment(order.id, order.paymentMethodId);
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Pembayaran berhasil dikonfirmasi!')),
                            );
                          }
                        },
                        child: const Text('Konfirmasi Pembayaran'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildTimeline(OrderModel order, ColorScheme colors) {
    final status = order.status.toLowerCase();
    
    final steps = [
      {'label': 'Pesan', 'active': true},
      {'label': 'Diproses', 'active': ['diproses', 'dikirim', 'tiba', 'selesai'].contains(status)},
      {'label': 'Dikirim', 'active': ['dikirim', 'tiba', 'selesai'].contains(status)},
      {'label': 'Selesai', 'active': ['selesai'].contains(status)},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isActive = step['active'] as bool;
        
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: Container(height: 2, color: index == 0 ? Colors.transparent : (isActive ? colors.primary : colors.outlineVariant))),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? colors.primary : colors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: isActive ? colors.primary : colors.outlineVariant, width: 2),
                    ),
                    child: isActive ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                  ),
                  Expanded(child: Container(height: 2, color: index == steps.length - 1 ? Colors.transparent : (steps[index + 1]['active'] as bool ? colors.primary : colors.outlineVariant))),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step['label'] as String,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? colors.primary : colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
