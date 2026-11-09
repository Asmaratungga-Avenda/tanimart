import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../services/api_service.dart';

/// State management untuk keranjang belanja.
/// Subtotal selalu berasal dari server (Single Source of Truth).
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  int _subtotal = 0;

  bool _isLoading = false;
  String? _errorMessage;

  List<CartItem> get items => _items;
  int get subtotal => _subtotal;
  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.jumlah);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;

  Future<void> loadCart() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await ApiService.getCart();
      _items = result.items;
      _subtotal = result.subtotal;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addItem(int produkId, int jumlah) async {
    _setLoading(true);
    _errorMessage = null;
    bool success = false;
    try {
      await ApiService.addCart(produkId, jumlah);
      await loadCart();
      success = true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> updateItem(int cartId, int jumlah) async {
    _setLoading(true);
    _errorMessage = null;
    bool success = false;
    try {
      await ApiService.updateCart(cartId, jumlah);
      await loadCart();
      success = true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> removeItem(int cartId) async {
    _setLoading(true);
    _errorMessage = null;
    bool success = false;
    try {
      await ApiService.deleteCart(cartId);
      await loadCart();
      success = true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> clearCart() async {
    _setLoading(true);
    _errorMessage = null;
    var success = false;
    try {
      await ApiService.clearCart();
      _items = [];
      _subtotal = 0;
      success = true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
