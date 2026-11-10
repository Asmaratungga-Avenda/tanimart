import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/formatters.dart';
import '../core/utils/order_status.dart';
import '../models/order.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/filter_pill.dart';
import '../widgets/inline_banner.dart';
import '../widgets/product_image.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';
import 'order_detail_page.dart';

enum _OrderFilter { all, waiting, processing, shipping, done }

extension on _OrderFilter {
  String get label => switch (this) {
    _OrderFilter.all => 'Semua',
    _OrderFilter.waiting => 'Menunggu',
    _OrderFilter.processing => 'Diproses',
    _OrderFilter.shipping => 'Dikirim',
    _OrderFilter.done => 'Selesai',
  };

  bool matches(String status) {
    final rank = OrderStatus.rank(status);
    return switch (this) {
      _OrderFilter.all => true,
      _OrderFilter.waiting => rank == 0 || rank == 1,
      _OrderFilter.processing => rank == 2 || rank == 3,
      _OrderFilter.shipping => rank == 4 || rank == 5,
      _OrderFilter.done => rank == 6,
    };
  }
}

/// Riwayat pesanan pelanggan dari server.
class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key, this.showBackButton = false});

  final bool showBackButton;

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  _OrderFilter _filter = _OrderFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<OrderProvider>().loadIfStale();
    });
  }

  void _open(OrderModel order) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailPage(orderId: order.id, initialOrder: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final orders = provider.orders.where((o) => _filter.matches(o.status)).toList();

    Widget body;
    if (!provider.hasLoaded && provider.isLoading) {
      body = const LoadingView();
    } else if (!provider.hasLoaded && provider.errorMessage != null) {
      body = RefreshIndicator(
        onRefresh: provider.loadOrders,
        child: ErrorView(
          message: provider.errorMessage!,
          onRetry: provider.loadOrders,
        ),
      );
    } else if (provider.orders.isEmpty) {
      body = RefreshIndicator(
        onRefresh: provider.loadOrders,
        child: EmptyView(
          icon: Icons.receipt_long_outlined,
          title: 'Belum ada pesanan',
          message: 'Pesanan yang Anda buat akan muncul di sini.',
          actionLabel: 'Mulai Belanja',
          onAction: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
            context.read<NavigationProvider>().select(AppTab.products);
          },
        ),
      );
    } else if (orders.isEmpty) {
      body = RefreshIndicator(
        onRefresh: provider.loadOrders,
        child: EmptyView(
          icon: Icons.filter_list_off_rounded,
          title: 'Tidak ada pesanan "${_filter.label}"',
          actionLabel: 'Lihat Semua',
          onAction: () => setState(() => _filter = _OrderFilter.all),
        ),
      );
    } else {
      final hasBanner = provider.errorMessage != null;
      body = RefreshIndicator(
        onRefresh: provider.loadOrders,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          itemCount: orders.length + (hasBanner ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (hasBanner) {
              if (index == 0) {
                return InlineBanner(
                  message: provider.errorMessage!,
                  icon: Icons.info_outline_rounded,
                  actionLabel: 'Muat ulang',
                  onAction: provider.loadOrders,
                );
              }
              index -= 1;
            }
            final order = orders[index];
            return _OrderCard(
              key: ValueKey<int>(order.id),
              order: order,
              onTap: () => _open(order),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: widget.showBackButton,
        titleSpacing: widget.showBackButton ? 0 : 16,
        title: const Text('Pesanan Saya'),
      ),
      body: Column(
        children: [
          if (provider.orders.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                itemCount: _OrderFilter.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final value = _OrderFilter.values[index];
                  return FilterPill(
                    label: value.label,
                    selected: _filter == value,
                    onTap: () => setState(() => _filter = value),
                  );
                },
              ),
            ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({super.key, required this.order, required this.onTap});

  final OrderModel order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final items = order.items;
    final thumbs = items.take(3).toList();
    final extra = items.length - thumbs.length;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pesanan #${order.id}', style: text.titleSmall),
              ),
              StatusBadge.order(order.status),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formatDateTime(order.createdAt),
            style: text.bodySmall?.copyWith(color: p.textSecondary),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                for (final item in thumbs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: ProductImage(
                          url: item.product?.foto ?? item.fotoProduk,
                          cacheWidth: 160,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ),
                if (extra > 0)
                  Text(
                    '+$extra',
                    style: text.labelMedium?.copyWith(color: p.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              items.map((i) => i.namaProduk).take(2).join(', ') +
                  (items.length > 2 ? ', dan ${items.length - 2} lainnya' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ],
          const Divider(height: 22),
          Row(
            children: [
              Text('Total', style: text.bodySmall),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatRupiah(order.totalHarga),
                  style: text.titleSmall?.copyWith(color: p.brandText),
                ),
              ),
              SecondaryButton(
                label: 'Lihat Detail',
                expanded: false,
                onPressed: onTap,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
