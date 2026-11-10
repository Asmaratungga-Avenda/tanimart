import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/widgets/product_image.dart';
import '../models/courier.dart';
import '../models/payment_method.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import 'order_history_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  DateTime _tanggalAntar = DateTime.now();
  String _slotPengantaran = 'pagi';

  List<Courier> _couriers = [];
  List<PaymentMethod> _paymentMethods = [];
  Courier? _selectedCourier;
  PaymentMethod? _selectedPaymentMethod;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _namaController.text = 'Pelanggan Setia';
    _alamatController.text = 'Rumah - Jl. Melati No. 123, Jakarta Selatan';
    _loadData();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getCouriers(),
        ApiService.getPaymentMethods(),
      ]);

      setState(() {
        _couriers = results[0] as List<Courier>;
        _paymentMethods = results[1] as List<PaymentMethod>;
        if (_couriers.isNotEmpty) _selectedCourier = _couriers.first;
        if (_paymentMethods.isNotEmpty) _selectedPaymentMethod = _paymentMethods.first;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _rupiah(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );

  Future<void> _submitCheckout() async {
    if (_selectedCourier == null || _selectedPaymentMethod == null) return;
    if (_namaController.text.isEmpty || _alamatController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama dan alamat harus diisi')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final cartProvider = context.read<CartProvider>();
      final payload = {
        'nama_penerima': _namaController.text,
        'alamat_penerima': _alamatController.text,
        'kurir_id': _selectedCourier!.id,
        'payment_method_id': _selectedPaymentMethod!.id,
        'tanggal_antar': _tanggalAntar.toIso8601String().split('T')[0],
        'slot_pengantaran': _slotPengantaran,
        'items': cartProvider.items.map((item) => {
          'product_id': item.id,
          'quantity': item.jumlah,
        }).toList(),
      };

      final idempotencyKey = 'checkout_${DateTime.now().millisecondsSinceEpoch}';
      await ApiService.checkout(payload, idempotencyKey: idempotencyKey);
      
      if (!mounted) return;
      
      // Clear cart provider after successful checkout
      context.read<CartProvider>().clearCart();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dibuat!'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Navigate to order history
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const OrderHistoryPage(showBackButton: true)),
        (route) => route.isFirst,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cartProvider = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      ElevatedButton(onPressed: _loadData, child: const Text('Coba Lagi')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionHeader('Informasi Penerima'),
                      TextField(
                        controller: _namaController,
                        decoration: InputDecoration(
                          labelText: 'Nama Penerima',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _alamatController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Alamat Lengkap',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('Jadwal Pengiriman'),
                      _infoCard(
                        icon: Icons.calendar_today_rounded,
                        title: 'Tanggal Antar: ${_tanggalAntar.toIso8601String().split('T')[0]}',
                        subtitle: 'Klik untuk mengubah tanggal',
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _tanggalAntar,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 7)),
                          );
                          if (date != null) setState(() => _tanggalAntar = date);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _slotPengantaran,
                        decoration: InputDecoration(
                          labelText: 'Slot Pengiriman',
                          prefixIcon: const Icon(Icons.access_time_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['pagi', 'siang', 'sore']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setState(() => _slotPengantaran = v!),
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('Kurir Pengiriman'),
                      _infoCard(
                        icon: Icons.local_shipping_rounded,
                        title: _selectedCourier?.nama ?? 'Pilih Kurir',
                        subtitle: _selectedCourier != null ? 'Estimasi 2-3 hari' : null,
                        onTap: () => _showCourierPicker(),
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('Metode Pembayaran'),
                      _infoCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: _selectedPaymentMethod?.nama ?? 'Pilih Pembayaran',
                        subtitle: _selectedPaymentMethod?.deskripsi,
                        onTap: () => _showPaymentMethodPicker(),
                      ),
                      const SizedBox(height: 20),
                      _sectionHeader('Ringkasan Pesanan'),
                      ...cartProvider.items.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: ProductImage(
                                    imageUrl: item.foto,
                                    productName: item.nama,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${item.nama} ${item.jumlah} ${item.satuanJual}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  'Rp ${_rupiah(item.harga * item.jumlah)}',
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          )),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'Rp ${_rupiah(cartProvider.subtotal)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submitCheckout,
                          child: _isSubmitting
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Bayar Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: TextButton(
          onPressed: onTap,
          child: const Text('Ubah'),
        ),
      ),
    );
  }

  void _showCourierPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Kurir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ..._couriers.map((c) => ListTile(
                  title: Text(c.nama),
                  trailing: _selectedCourier?.id == c.id ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _selectedCourier = c);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pilih Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            ..._paymentMethods.map((pm) => ListTile(
                  title: Text(pm.nama),
                  subtitle: Text(pm.deskripsi ?? ''),
                  trailing: _selectedPaymentMethod?.id == pm.id ? const Icon(Icons.check, color: Colors.green) : null,
                  onTap: () {
                    setState(() => _selectedPaymentMethod = pm);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}
