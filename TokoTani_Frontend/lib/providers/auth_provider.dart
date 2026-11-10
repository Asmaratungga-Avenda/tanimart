import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

/// Status sesi pelanggan.
///
/// `isInitializing` hanya aktif saat aplikasi memeriksa token tersimpan,
/// sedangkan `isSubmitting` aktif saat login/daftar. Keduanya dipisah agar
/// formulir login tidak hilang dari layar ketika proses masuk berjalan atau gagal.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    ApiService.onUnauthorized = _handleUnauthorized;
  }

  Map<String, dynamic>? _user;
  bool _isInitializing = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  Map<String, String> _fieldErrors = const {};
  String? _sessionError;

  Map<String, dynamic>? get user => _user;
  bool get isInitializing => _isInitializing;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  Map<String, String> get fieldErrors => _fieldErrors;
  String? get sessionError => _sessionError;
  bool get isAuthenticated => _user != null;

  int? get userId => int.tryParse('${_user?['id']}');
  String get displayName {
    final name = _user?['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Pelanggan' : name;
  }

  String get firstName => displayName.split(' ').first;
  String get email => _user?['email']?.toString() ?? '';

  void clearError() {
    if (_errorMessage == null && _fieldErrors.isEmpty) return;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();
  }

  Future<void> initialize() async {
    _isInitializing = true;
    _sessionError = null;
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
    } catch (_) {
      _sessionError = 'Sesi belum dapat diperiksa. Periksa koneksi Anda.';
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) =>
      _authenticate(() => ApiService.login(email, password));

  Future<bool> register(String name, String email, String password) =>
      _authenticate(() => ApiService.register(name, email, password));

  Future<bool> _authenticate(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    _fieldErrors = const {};
    notifyListeners();
    try {
      _user = await action();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _fieldErrors = error.fieldErrors;
      return false;
    } catch (_) {
      _errorMessage = 'Terjadi gangguan. Silakan coba lagi.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Keluar dari akun. Mengembalikan false bila token server gagal dicabut
  /// (sesi di perangkat tetap ditutup).
  Future<bool> signOut() async {
    var serverRevoked = true;
    _errorMessage = null;
    try {
      await ApiService.logout();
    } catch (_) {
      serverRevoked = false;
      await ApiService.clearAuthToken();
    } finally {
      _user = null;
      notifyListeners();
    }
    return serverRevoked;
  }

  Future<void> retrySession() => initialize();

  /// Server menjawab 401 saat sesi aktif: token sudah tidak berlaku.
  void _handleUnauthorized() {
    if (_user == null) return;
    _user = null;
    _errorMessage = 'Sesi Anda berakhir. Silakan masuk kembali.';
    ApiService.clearAuthToken();
    notifyListeners();
  }

  @override
  void dispose() {
    if (ApiService.onUnauthorized == _handleUnauthorized) {
      ApiService.onUnauthorized = null;
    }
    super.dispose();
  }
}
