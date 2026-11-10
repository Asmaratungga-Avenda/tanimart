import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
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
  String _selectedFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().loadOrders();
    });
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
    
    List<OrderModel> orders = provider.orders;
    if (_selectedFilter != 'Semua') {
      orders = orders.where((o) => _getStatusLabel(o.status).contains(_selectedFilter)).toList();
    }

    return Scaffold(
      appBar: AppBar(
        leading: widget.showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          _buildFilters(colors),
          Expanded(
            child: provider.isLoading && provider.orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                    ? _buildEmptyState(colors)
                    : RefreshIndicator(
                        onRefresh: () => provider.loadOrders(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return _buildOrderCard(order, colors, theme);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ColorScheme colors) {
    final filters = ['Semua', 'Diproses', 'Dikirim', 'Selesai'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, i) {
          final filter = filters[i];
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              selectedColor: colors.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              showCheckmark: false,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: colors.outlineVariant),
          const SizedBox(height: 16),
          const Text(
            'Belum ada pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text('Ayo mulai belanja kebutuhanmu!'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (widget.onGoToCatalog != null) {
                widget.onGoToCatalog!();
              } else {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            child: const Text('Belanja Sekarang'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, ColorScheme colors, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OrderDetailPage(orderId: order.id, initialOrder: order)),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.nomorPesanan,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                order.createdAt.toString().substring(0, 16), // Simplified date
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_basket_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.items.length} Produk',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          'Total Pembayaran',
                          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Rp ${_rupiah(order.totalHarga)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
