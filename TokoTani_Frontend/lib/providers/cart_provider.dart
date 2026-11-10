import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../services/api_service.dart';

/// State keranjang. Isi dan subtotal selalu berasal dari server.
///
/// Muat ulang (`isLoading`) dipisah dari aksi per-baris (`isItemBusy`,
/// `isAdding`) sehingga daftar tidak berganti spinner setiap kali jumlah diubah.
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = const [];
  int _subtotal = 0;
  bool _isLoading = false;
  bool _hasLoaded = false;
  bool _isClearing = false;
  String? _errorMessage;
  int _loadSeq = 0;
  int? _userId;
  DateTime? _lastLoaded;

  final Set<int> _busyItemIds = <int>{};
  final Set<int> _addingProductIds = <int>{};

  List<CartItem> get items => _items;
  int get subtotal => _subtotal;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  bool get isClearing => _isClearing;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;

  /// Jumlah baris produk di keranjang (untuk lencana).
  int get badgeCount => _items.length;

  bool isItemBusy(int cartId) => _busyItemIds.contains(cartId);
  bool isAdding(int productId) => _addingProductIds.contains(productId);
  bool get isMutating =>
      _busyItemIds.isNotEmpty || _addingProductIds.isNotEmpty || _isClearing;

  /// Dipanggil saat pengguna berganti: data akun lama tidak boleh tersisa.
  void bindUser(int? userId) {
    if (userId == _userId) return;
    _userId = userId;
    _loadSeq++;
    _items = const [];
    _subtotal = 0;
    _isLoading = false;
    _hasLoaded = false;
    _isClearing = false;
    _errorMessage = null;
    _lastLoaded = null;
    _busyItemIds.clear();
    _addingProductIds.clear();
  }

  /// Memuat ulang hanya bila data sudah lebih tua dari [maxAge].
  Future<void> loadIfStale({Duration maxAge = const Duration(seconds: 20)}) {
    if (_isLoading) return Future<void>.value();
    final last = _lastLoaded;
    if (last != null && DateTime.now().difference(last) < maxAge) {
      return Future<void>.value();
    }
    return loadCart();
  }

  Future<void> loadCart() async {
    final seq = ++_loadSeq;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final result = await ApiService.getCart();
      if (seq != _loadSeq) return;
      _items = result.items;
      _subtotal = result.subtotal;
      _hasLoaded = true;
      _lastLoaded = DateTime.now();
    } on ApiException catch (e) {
      if (seq != _loadSeq) return;
      _errorMessage = e.message;
    } catch (_) {
      if (seq != _loadSeq) return;
      _errorMessage = 'Keranjang belum dapat dimuat. Silakan coba lagi.';
    } finally {
      if (seq == _loadSeq) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Mengembalikan null bila berhasil, atau pesan galat dari server.
  Future<String?> addItem(int productId, int quantity) async {
    if (_addingProductIds.contains(productId)) {
      return 'Produk sedang ditambahkan, mohon tunggu.';
    }
    _addingProductIds.add(productId);
    notifyListeners();
    try {
      await ApiService.addCart(productId, quantity);
      await loadCart();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Produk belum dapat ditambahkan. Silakan coba lagi.';
    } finally {
      _addingProductIds.remove(productId);
      notifyListeners();
    }
  }

  Future<String?> updateItem(int cartId, int quantity) async {
    if (_busyItemIds.contains(cartId)) return null;
    _busyItemIds.add(cartId);
    notifyListeners();
    try {
      await ApiService.updateCart(cartId, quantity);
      await loadCart();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Jumlah belum dapat diubah. Silakan coba lagi.';
    } finally {
      _busyItemIds.remove(cartId);
      notifyListeners();
    }
  }

  Future<String?> removeItem(int cartId) async {
    if (_busyItemIds.contains(cartId)) return null;
    _busyItemIds.add(cartId);
    notifyListeners();
    try {
      await ApiService.deleteCart(cartId);
      await loadCart();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Produk belum dapat dihapus. Silakan coba lagi.';
    } finally {
      _busyItemIds.remove(cartId);
      notifyListeners();
    }
  }

  Future<String?> clearCart() async {
    if (_isClearing) return null;
    _isClearing = true;
    notifyListeners();
    try {
      await ApiService.clearCart();
      await loadCart();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Keranjang belum dapat dikosongkan. Silakan coba lagi.';
    } finally {
      _isClearing = false;
      notifyListeners();
    }
  }
}
