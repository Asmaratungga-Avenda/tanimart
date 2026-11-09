import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _user;
  bool _isLoading = true;
  String? _errorMessage;
  String? _sessionError;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get sessionError => _sessionError;
  bool get isAuthenticated => _user != null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> initialize() async {
    try {
      final token = await ApiService.readAuthToken();
      if (token != null && token.isNotEmpty) {
        _user = await ApiService.currentUser();
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await ApiService.clearAuthToken();
      } else {
        _sessionError = error.message;
      }
    } catch (error) {
      _sessionError = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await ApiService.login(email, password);
      return true;
    } on Exception catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _user = await ApiService.register(name, email, password);
      return true;
    } on Exception catch (error) {
      _errorMessage = error.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    var serverRevoked = true;
    _errorMessage = null;
    try {
      await ApiService.logout();
    } on Exception catch (error) {
      serverRevoked = false;
      _errorMessage = error.toString();
      await ApiService.clearAuthToken();
    } finally {
      _user = null;
      notifyListeners();
    }
    return serverRevoked;
  }

  Future<void> retrySession() async {
    _isLoading = true;
    _sessionError = null;
    notifyListeners();
    await initialize();
  }
}
