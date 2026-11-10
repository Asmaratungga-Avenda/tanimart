import 'package:shared_preferences/shared_preferences.dart';

/// Alamat terakhir yang diisi pelanggan saat checkout, disimpan di perangkat
/// agar tidak perlu mengetik ulang. API belum memiliki buku alamat.
class SavedAddress {
  final String name;
  final String address;

  const SavedAddress({required this.name, required this.address});
}

class AddressStore {
  const AddressStore._();

  static String _key(int? userId, String field) =>
      'checkout_${field}_${userId ?? 0}';

  static Future<SavedAddress?> load(int? userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_key(userId, 'name'));
      final address = prefs.getString(_key(userId, 'address'));
      if (address == null || address.trim().isEmpty) return null;
      return SavedAddress(name: name ?? '', address: address);
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int? userId, SavedAddress value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId, 'name'), value.name);
      await prefs.setString(_key(userId, 'address'), value.address);
    } catch (_) {
      // Gagal menyimpan alamat tidak boleh menghalangi pesanan.
    }
  }
}
