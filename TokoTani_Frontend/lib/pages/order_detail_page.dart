import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/formatters.dart';
import '../core/utils/order_status.dart';
import '../core/utils/ui.dart';
import '../models/order.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/inline_banner.dart';
import '../widgets/product_image.dart';
import '../widgets/state_views.dart';
import '../widgets/status_badge.dart';

/// Rincian pesanan: status, pengiriman, produk, pembayaran, dan aksi pelanggan.
class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({super.key, required this.orderId, this.initialOrder});

  final int orderId;
  final OrderModel? initialOrder;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final error = await context.read<OrderProvider>().loadDetail(widget.orderId);
    if (mounted) setState(() => _loadError = error);
  }

  Future<void> _pay(OrderModel order) async {
    final provider = context.read<OrderProvider>();
    final error = await provider.confirmPayment(order.id, order.paymentMethodId);
    if (!mounted) return;
    if (error != null) {
      showAppSnack(context, error, error: true);
    } else {
      showAppSnack(context, 'Konfirmasi pembayaran terkirim. Menunggu verifikasi.');
    }
  }

  Future<void> _complete(OrderModel order) async {
    final ok = await confirmDialog(
      context,
      title: 'Pesanan sudah diterima?',
      message: 'Pastikan semua produk sudah Anda terima dengan baik.',
      confirmLabel: 'Pesanan Selesai',
    );
    if (!ok || !mounted) return;
    final error = await context.read<OrderProvider>().completeOrder(order.id);
    if (!mounted) return;
    if (error != null) {
      showAppSnack(context, error, error: true);
    } else {
      showAppSnack(context, 'Pesanan selesai. Terima kasih sudah berbelanja!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = provider.detail(widget.orderId) ?? widget.initialOrder;
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Pesanan')),
        body: provider.isLoadingDetail(widget.orderId)
            ? const LoadingView()
            : ErrorView(
                message: _loadError ?? 'Pesanan tidak ditemukan.',
                onRetry: _load,
              ),
      );
    }

    final busy = provider.isBusy(order.id);
    final canPay = OrderStatus.canPay(order.status);
    final canComplete = OrderStatus.canComplete(order.status);

    return Scaffold(
      appBar: AppBar(title: Text('Pesanan #${order.id}')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          children: [
            if (_loadError != null) ...[
              InlineBanner(
                message: _loadError!,
                icon: Icons.info_outline_rounded,
                actionLabel: 'Muat ulang',
                onAction: _load,
              ),
              const SizedBox(height: 12),
            ],
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Pesanan #${order.id}',
                          style: text.titleMedium,
                        ),
                      ),
                      StatusBadge.order(order.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatDateTime(order.createdAt),
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                  const SizedBox(height: 18),
                  _StatusStepper(status: order.status),
                  const SizedBox(height: 14),
                  Text(
                    _hint(order.status),
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Block(
              title: 'Pengiriman',
              icon: Icons.local_shipping_outlined,
              children: [
                _Line('Penerima', order.namaPenerima),
                _Line('Alamat', order.alamatPenerima),
                _Line('Kurir', order.courier?.nama ?? '-'),
                _Line('Tanggal antar', formatDate(order.tanggalAntar)),
              ],
            ),
            const SizedBox(height: 12),
            _Block(
              title: 'Produk Pesanan',
              icon: Icons.shopping_basket_outlined,
              children: [
                if (order.items.isEmpty)
                  Text(
                    'Rincian produk belum tersedia.',
                    style: text.bodySmall?.copyWith(color: p.textSecondary),
                  ),
                for (final item in order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ProductImage(
                            url: item.product?.foto ?? item.fotoProduk,
                            cacheWidth: 180,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.namaProduk,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleSmall,
                              ),
                              Text(
                                '${item.quantity} × ${formatRupiah(item.hargaSatuan)}',
                                style: text.bodySmall?.copyWith(
                                  color: p.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatRupiah(item.subtotal),
                          style: text.titleSmall,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _Block(
              title: 'Ringkasan Pembayaran',
              icon: Icons.account_balance_wallet_outlined,
              children: [
                _Line('Metode', order.paymentMethod?.nama ?? '-'),
                _Line('Subtotal', formatRupiah(order.subtotal)),
                _Line('Ongkos kirim', formatRupiah(order.ongkir)),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(child: Text('Total', style: text.titleSmall)),
                    Text(
                      formatRupiah(order.totalHarga),
                      style: text.titleMedium?.copyWith(color: p.brandText),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: (canPay || canComplete)
          ? Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: canPay
                      ? PrimaryButton(
                          label: 'Konfirmasi Pembayaran',
                          icon: Icons.verified_outlined,
                          loading: busy,
                          onPressed: () => _pay(order),
                        )
                      : PrimaryButton(
                          label: 'Pesanan Selesai',
                          icon: Icons.check_circle_outline_rounded,
                          loading: busy,
                          onPressed: () => _complete(order),
                        ),
                ),
              ),
            )
          : OrderStatus.rank(order.status) == 6
          ? Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: SecondaryButton(
                    label: 'Belanja Kebutuhan Lainnya',
                    icon: Icons.storefront_outlined,
                    onPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      context.read<NavigationProvider>().select(AppTab.products);
                    },
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _hint(String status) {
    switch (OrderStatus.normalize(status)) {
      case OrderStatus.waitingPayment:
        return 'Lakukan pembayaran sesuai metode yang dipilih, lalu tekan Konfirmasi Pembayaran.';
      case OrderStatus.waitingConfirmation:
        return 'Pembayaran Anda sedang diverifikasi oleh toko.';
      case OrderStatus.paid:
      case OrderStatus.processing:
        return 'Pesanan sedang disiapkan oleh penjual.';
      case OrderStatus.shipping:
        return 'Kurir sedang mengantar pesanan Anda.';
      case OrderStatus.arrived:
        return 'Pesanan sudah tiba. Periksa produk, lalu tekan Pesanan Selesai.';
      case OrderStatus.completed:
        return 'Pesanan selesai. Terima kasih sudah berbelanja di TaniMart.';
      case OrderStatus.cancelled:
        return 'Pesanan ini dibatalkan.';
      default:
        return 'Status pesanan: ${OrderStatus.label(status)}.';
    }
  }
}

/// Stepper horizontal 4 tahap: Dibuat - Diproses - Dikirim - Selesai.
class _StatusStepper extends StatelessWidget {
  const _StatusStepper({required this.status});

  final String status;

  static const List<String> _labels = [
    'Pesanan\nDibuat',
    'Diproses',
    'Dikirim',
    'Selesai',
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final rank = OrderStatus.rank(status);

    if (OrderStatus.normalize(status) == OrderStatus.cancelled) {
      return Row(
        children: [
          Icon(Icons.cancel_rounded, color: p.danger),
          const SizedBox(width: 8),
          Text(
            'Pesanan dibatalkan',
            style: text.titleSmall?.copyWith(color: p.danger),
          ),
        ],
      );
    }

    // Tahap aktif: 0 dibuat/menunggu bayar, 1 diproses, 2 dikirim, 3 selesai.
    final current = rank <= 1 ? 0 : rank <= 3 ? 1 : rank <= 5 ? 2 : 3;
    final allDone = rank == 6;

    Widget node(int i) {
      final done = i < current || (allDone && i == 3);
      final active = i == current && !allDone;
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done ? p.brand : p.card,
          border: Border.all(
            color: done || active ? p.brand : p.border,
            width: 2,
          ),
        ),
        child: done
            ? Icon(Icons.check_rounded, size: 16, color: p.onBrand)
            : active
            ? Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: p.brand,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      );
    }

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              node(i),
              if (i < 3)
                Expanded(
                  child: Container(
                    height: 2,
                    color: i < current || allDone ? p.brand : p.border,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(
                width: 64,
                child: Text(
                  _labels[i],
                  textAlign: i == 0
                      ? TextAlign.left
                      : i == 3
                      ? TextAlign.right
                      : TextAlign.center,
                  style: text.labelSmall?.copyWith(
                    color: i <= current || allDone
                        ? p.textPrimary
                        : p.textSecondary,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: p.brandText),
              const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: text.bodySmall?.copyWith(color: p.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.end,
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
