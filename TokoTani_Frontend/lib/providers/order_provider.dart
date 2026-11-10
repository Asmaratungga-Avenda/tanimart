import 'package:flutter/foundation.dart';

import '../models/order.dart';
import '../services/api_service.dart';

/// Riwayat dan rincian pesanan, seluruhnya dari server.
class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = const [];
  final Map<int, OrderModel> _details = <int, OrderModel>{};

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  int _loadSeq = 0;
  int? _userId;
  DateTime? _lastLoaded;

  final Set<int> _loadingDetailIds = <int>{};
  final Set<int> _busyOrderIds = <int>{};

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _orders.isEmpty;

  OrderModel? detail(int id) => _details[id];
  bool isLoadingDetail(int id) => _loadingDetailIds.contains(id);
  bool isBusy(int id) => _busyOrderIds.contains(id);

  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _loadSeq++;
    _orders = const [];
    _details.clear();
    _isLoading = false;
    _hasLoaded = false;
    _errorMessage = null;
    _lastLoaded = null;
    _loadingDetailIds.clear();
    _busyOrderIds.clear();
  }

  Future<void> loadIfStale({Duration maxAge = const Duration(seconds: 20)}) {
    if (_isLoading) return Future<void>.value();
    final last = _lastLoaded;
    if (last != null && DateTime.now().difference(last) < maxAge) {
      return Future<void>.value();
    }
    return loadOrders();
  }

  Future<void> loadOrders() async {
    final seq = ++_loadSeq;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getOrders();
      if (seq != _loadSeq) return;
      _orders = _sortNewestFirst(result);
      _hasLoaded = true;
      _lastLoaded = DateTime.now();
    } on ApiException catch (e) {
      if (seq != _loadSeq) return;
      _errorMessage = e.message;
    } catch (_) {
      if (seq != _loadSeq) return;
      _errorMessage = 'Pesanan belum dapat dimuat. Silakan coba lagi.';
    } finally {
      if (seq == _loadSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Memuat rincian pesanan. Mengembalikan pesan galat bila gagal.
  Future<String?> loadDetail(int id) async {
    if (_loadingDetailIds.contains(id)) return null;
    _loadingDetailIds.add(id);
    notifyListeners();
    String? error;
    try {
      _store(await ApiService.getOrder(id));
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Rincian pesanan belum dapat dimuat. Silakan coba lagi.';
    } finally {
      _loadingDetailIds.remove(id);
      notifyListeners();
    }
    return error;
  }

  /// Menyimpan pesanan baru (misalnya hasil checkout) tanpa request tambahan.
  void upsert(OrderModel order) {
    _store(order);
    notifyListeners();
  }

  /// Pelanggan menandai pesanan selesai. Mengembalikan null bila berhasil.
  Future<String?> completeOrder(int id) => _mutate(
    id,
    () => ApiService.updateOrderStatus(id, 'selesai'),
    'Pesanan belum dapat diselesaikan. Silakan coba lagi.',
  );

  Future<String?> confirmPayment(int id, int paymentMethodId) => _mutate(
    id,
    () => ApiService.confirmPayment(id, paymentMethodId),
    'Pembayaran belum dapat dikonfirmasi. Silakan coba lagi.',
  );

  Future<String?> _mutate(
    int id,
    Future<OrderModel> Function() action,
    String fallbackMessage,
  ) async {
    if (_busyOrderIds.contains(id)) return null;
    _busyOrderIds.add(id);
    notifyListeners();
    try {
      _store(await action());
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return fallbackMessage;
    } finally {
      _busyOrderIds.remove(id);
      notifyListeners();
    }
  }

  void _store(OrderModel order) {
    final previous = _details[order.id];
    // Respons ringkas (mis. dari aksi status) bisa tanpa item; jangan hilangkan item lama.
    final merged = order.items.isEmpty && previous != null
        ? _withItems(order, previous)
        : order;
    _details[order.id] = merged;

    final index = _orders.indexWhere((o) => o.id == order.id);
    final next = List<OrderModel>.of(_orders);
    if (index == -1) {
      next.insert(0, merged);
    } else {
      next[index] = merged;
    }
    _orders = _sortNewestFirst(next);
  }

  OrderModel _withItems(OrderModel order, OrderModel source) => OrderModel(
    id: order.id,
    namaPenerima: order.namaPenerima,
    alamatPenerima: order.alamatPenerima,
    kurirId: order.kurirId,
    courier: order.courier ?? source.courier,
    paymentMethodId: order.paymentMethodId,
    paymentMethod: order.paymentMethod ?? source.paymentMethod,
    subtotal: order.subtotal,
    ongkir: order.ongkir,
    totalHarga: order.totalHarga,
    status: order.status,
    tanggalAntar: order.tanggalAntar,
    createdAt: order.createdAt ?? source.createdAt,
    idempotencyKey: order.idempotencyKey,
    items: source.items,
  );

  List<OrderModel> _sortNewestFirst(List<OrderModel> list) {
    final sorted = List<OrderModel>.of(list);
    sorted.sort((a, b) {
      final da = DateTime.tryParse(a.createdAt ?? '');
      final db = DateTime.tryParse(b.createdAt ?? '');
      if (da != null && db != null) {
        final byDate = db.compareTo(da);
        if (byDate != 0) return byDate;
      }
      return b.id.compareTo(a.id);
    });
    return sorted;
  }
}
