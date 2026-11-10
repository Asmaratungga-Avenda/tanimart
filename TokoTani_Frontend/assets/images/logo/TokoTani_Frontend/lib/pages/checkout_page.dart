import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_palette.dart';
import '../core/utils/formatters.dart';
import '../core/utils/order_status.dart';
import '../core/utils/ui.dart';
import '../models/courier.dart';
import '../models/order.dart';
import '../models/payment_method.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/order_provider.dart';
import '../services/address_store.dart';
import '../services/api_service.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/inline_banner.dart';
import '../widgets/option_tile.dart';
import '../widgets/state_views.dart';
import 'order_detail_page.dart';

/// Checkout satu halaman: alamat, kurir, pembayaran, ringkasan.
/// Total akhir ditentukan server; angka di sini hanya perkiraan.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();

  List<Courier> _couriers = const [];
  List<PaymentMethod> _payments = const [];
  Courier? _courier;
  PaymentMethod? _payment;
  DateTime _deliveryDate = DateTime.now();

  bool _loadingOptions = true;
  String? _optionsError;
  bool _submitting = false;
  String? _idempotencyKey;
  Map<String, String> _serverErrors = const {};
  String? _conflictMessage;
  String? _generalError;

  @override
  void initState() {
    super.initState();
    _prefill();
    _loadOptions();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CartProvider>().loadIfStale();
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _prefill() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;
    final accountName = auth.user?['name']?.toString() ?? '';
    final saved = await AddressStore.load(userId);
    if (!mounted) return;
    if (_name.text.isEmpty) {
      _name.text = (saved?.name.isNotEmpty ?? false) ? saved!.name : accountName;
    }
    if (_address.text.isEmpty && saved != null) _address.text = saved.address;
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
    });
    try {
      final results = await Future.wait<Object>([
        ApiService.getCouriers(),
        ApiService.getPaymentMethods(),
      ]);
      if (!mounted) return;
      final couriers = (results[0] as List<Courier>).where((c) => c.aktif).toList();
      final payments = (results[1] as List<PaymentMethod>)
          .where((m) => m.aktif)
          .toList();
      setState(() {
        _couriers = couriers;
        _payments = payments;
        _courier = _keep(couriers, _courier?.id, (c) => c.id);
        _payment = _keep(payments, _payment?.id, (m) => m.id);
        if (couriers.isEmpty || payments.isEmpty) {
          _optionsError = couriers.isEmpty
              ? 'Belum ada kurir yang aktif. Hubungi toko.'
              : 'Belum ada metode pembayaran yang aktif. Hubungi toko.';
        }
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _optionsError = e.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _optionsError = 'Pilihan pengiriman belum dapat dimuat.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  T? _keep<T>(List<T> list, int? id, int Function(T) idOf) {
    if (list.isEmpty) return null;
    if (id != null) {
      for (final item in list) {
        if (idOf(item) == id) return item;
      }
    }
    return list.first;
  }

  String _newKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(12, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'tm-${DateTime.now().microsecondsSinceEpoch}-$hex';
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate.isBefore(first) ? first : _deliveryDate,
      firstDate: first,
      lastDate: first.add(const Duration(days: 30)),
      helpText: 'Tanggal pengiriman',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) {
      setState(() {
        _deliveryDate = picked;
        _serverErrors = {..._serverErrors}..remove('tanggal_antar');
      });
    }
  }

  void _clearFieldError(String key) {
    if (_serverErrors.containsKey(key)) {
      setState(() => _serverErrors = {..._serverErrors}..remove(key));
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final cart = context.read<CartProvider>();
    if (cart.isEmpty) {
      showAppSnack(context, 'Keranjang kosong.', error: true);
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final courier = _courier;
    final payment = _payment;
    if (courier == null || payment == null) {
      showAppSnack(context, 'Pilih kurir dan metode pembayaran.', error: true);
      return;
    }
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final orders = context.read<OrderProvider>();
    final navigator = Navigator.of(context);

    setState(() {
      _submitting = true;
      _serverErrors = const {};
      _conflictMessage = null;
      _generalError = null;
    });

    final key = _idempotencyKey ??= _newKey();
    final recipient = _name.text.trim();
    final address = _address.text.trim();

    try {
      final response = await ApiService.checkout({
        'nama_penerima': recipient,
        'alamat_penerima': address,
        'kurir_id': courier.id,
        'payment_method_id': payment.id,
        'tanggal_antar': toApiDate(_deliveryDate),
        'items': [
          for (final item in cart.items)
            {'product_id': item.produkId, 'quantity': item.jumlah},
        ],
      }, idempotencyKey: key);

      final data = response['data'];
      if (data is! Map) {
        throw const FormatException('Respons pesanan tidak dikenali.');
      }
      final order = OrderModel.fromJson(Map<String, dynamic>.from(data));
      _idempotencyKey = null;

      orders.upsert(order);
      unawaited(cart.loadCart());
      unawaited(
        AddressStore.save(
          auth.userId,
          SavedAddress(name: recipient, address: address),
        ),
      );
      if (!mounted) return;
      await navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailPage(orderId: order.id, initialOrder: order),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 422) {
        _idempotencyKey = null;
        setState(() => _serverErrors = e.fieldErrors);
        setState(() => _generalError = e.message);
        _formKey.currentState?.validate();
      } else if (e.statusCode == 409) {
        _idempotencyKey = null;
        setState(() => _conflictMessage = e.message);
        unawaited(cart.loadCart());
      } else {
        setState(() => _generalError = e.message);
      }
    } on FormatException {
      if (!mounted) return;
      unawaited(cart.loadCart());
      setState(() {
        _generalError =
            'Pesanan kemungkinan sudah dibuat, tetapi rinciannya belum terbaca. '
            'Periksa tab Pesanan sebelum mencoba lagi.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _generalError = 'Pesanan belum dapat dikirim. Silakan coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final p = context.palette;
    final text = Theme.of(context).textTheme;

    Widget body;
    if (!cart.hasLoaded && cart.isLoading) {
      body = const LoadingView();
    } else if (!cart.hasLoaded && cart.errorMessage != null) {
      body = ErrorView(message: cart.errorMessage!, onRetry: cart.loadCart);
    } else if (cart.isEmpty) {
      body = EmptyView(
        icon: Icons.shopping_basket_outlined,
        title: 'Keranjang kosong',
        message: 'Tambahkan produk dulu sebelum checkout.',
        actionLabel: 'Belanja Sekarang',
        onAction: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.read<NavigationProvider>().select(AppTab.products);
        },
      );
    } else if (_loadingOptions) {
      body = const LoadingView();
    } else if (_optionsError != null && (_couriers.isEmpty || _payments.isEmpty)) {
      body = ErrorView(message: _optionsError!, onRetry: _loadOptions);
    } else {
      final shipping = _courier?.tarif ?? 0;
      body = Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            if (_conflictMessage != null) ...[
              InlineBanner(
                title: 'Stok atau harga berubah',
                message: _conflictMessage!,
                tone: StatusTone.warning,
                icon: Icons.warning_amber_rounded,
                actionLabel: 'Periksa keranjang',
                onAction: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  context.read<NavigationProvider>().select(AppTab.cart);
                },
              ),
              const SizedBox(height: 12),
            ],
            if (_generalError != null) ...[
              InlineBanner(message: _generalError!),
              const SizedBox(height: 12),
            ],
            _Section(
              icon: Icons.location_on_outlined,
              title: 'Alamat Pengiriman',
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Nama penerima',
                      errorText: _serverErrors['nama_penerima'],
                    ),
                    onChanged: (_) => _clearFieldError('nama_penerima'),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama penerima wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _address,
                    minLines: 2,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      labelText: 'Alamat lengkap',
                      alignLabelWithHint: true,
                      errorText: _serverErrors['alamat_penerima'],
                    ),
                    onChanged: (_) => _clearFieldError('alamat_penerima'),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Alamat wajib diisi';
                      if (value.length < 10) {
                        return 'Tulis alamat selengkapnya (min. 10 karakter)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tanggal pengiriman',
                        errorText: _serverErrors['tanggal_antar'],
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        formatDate(toApiDate(_deliveryDate)),
                        style: text.bodyLarge,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.local_shipping_outlined,
              title: 'Kurir Pengiriman',
              error: _serverErrors['kurir_id'],
              child: Column(
                children: [
                  for (final courier in _couriers) ...[
                    OptionTile(
                      title: courier.nama,
                      trailing: formatRupiah(courier.tarif),
                      selected: _courier?.id == courier.id,
                      onTap: () => setState(() => _courier = courier),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Metode Pembayaran',
              error: _serverErrors['payment_method_id'],
              child: Column(
                children: [
                  for (final method in _payments) ...[
                    OptionTile(
                      title: method.nama,
                      subtitle: method.deskripsi,
                      selected: _payment?.id == method.id,
                      onTap: () => setState(() => _payment = method),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Section(
              icon: Icons.receipt_long_outlined,
              title: 'Ringkasan Pesanan',
              child: Column(
                children: [
                  for (final item in cart.items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.nama} · ${item.jumlah} ${item.satuanJual}',
                              style: text.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  _SummaryRow('Subtotal produk', formatRupiah(cart.subtotal)),
                  const SizedBox(height: 6),
                  _SummaryRow('Ongkos kirim', formatRupiah(shipping)),
                  const SizedBox(height: 10),
                  _SummaryRow(
                    'Perkiraan total',
                    formatRupiah(cart.subtotal + shipping),
                    bold: true,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total akhir dihitung server saat pesanan dibuat.',
                      style: text.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final canSubmit = cart.hasLoaded &&
        !cart.isEmpty &&
        !_loadingOptions &&
        _courier != null &&
        _payment != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: body,
      bottomNavigationBar: canSubmit
          ? Container(
              decoration: BoxDecoration(
                color: p.surface,
                border: Border(top: BorderSide(color: p.border)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: PrimaryButton(
                    label: 'Buat Pesanan',
                    trailing: formatRupiah(cart.subtotal + (_courier?.tarif ?? 0)),
                    loading: _submitting,
                    onPressed: _submit,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    this.error,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: p.brandText),
              const SizedBox(width: 8),
              Text(title, style: text.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          child,
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                error!,
                style: text.bodySmall?.copyWith(color: p.danger),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold
                ? text.titleSmall
                : text.bodyMedium?.copyWith(color: p.textSecondary),
          ),
        ),
        Text(
          value,
          style: bold
              ? text.titleMedium?.copyWith(color: p.brandText)
              : text.bodyMedium,
        ),
      ],
    );
  }
}
