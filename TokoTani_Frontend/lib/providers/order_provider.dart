import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/api_service.dart';

/// State management untuk riwayat dan rincian pesanan.
class OrderProvider extends ChangeNotifier {
  List<OrderModel> _orders = [];
  OrderModel? _orderDetail;

  bool _isLoading = false;
  String? _errorMessage;

  List<OrderModel> get orders => _orders;
  OrderModel? get orderDetail => _orderDetail;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _orders.isEmpty;

  Future<void> loadOrders() async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final result = await ApiService.getOrders();
      _orders = result;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<OrderModel?> loadOrderDetail(int id) async {
    _setLoading(true);
    _errorMessage = null;
    OrderModel? result;
    try {
      result = await ApiService.getOrder(id);
      _orderDetail = result;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return result;
  }

  Future<bool> updateOrderStatus(int id, String status) async {
    _setLoading(true);
    _errorMessage = null;
    bool success = false;
    try {
      final updated = await ApiService.updateOrderStatus(id, status);
      _orderDetail = updated;
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        _orders[index] = updated;
      }
      success = true;
    } on Exception catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
    return success;
  }

  Future<bool> confirmPayment(int id, int paymentMethodId) async {
    _setLoading(true);
    _errorMessage = null;
    var success = false;
    try {
      final updated = await ApiService.confirmPayment(id, paymentMethodId);
      _orderDetail = updated;
      final index = _orders.indexWhere((order) => order.id == id);
      if (index != -1) {
        _orders[index] = updated;
      }
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
