import 'package:shared_preferences/shared_preferences.dart';

/// Alamat terakhir yang diisi pelanggan saat checkout, disimpan di perangkat
/// agar tidak perlu mengetik ulang. API belum memiliki buku alamat.
class SavedAddress {
  const SavedAddress({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.accuracy,
  });

  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
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
      return SavedAddress(
        name: name ?? '',
        address: address,
        latitude: prefs.getDouble(_key(userId, 'latitude')),
        longitude: prefs.getDouble(_key(userId, 'longitude')),
        accuracy: prefs.getDouble(_key(userId, 'accuracy')),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> save(int? userId, SavedAddress value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(userId, 'name'), value.name);
      await prefs.setString(_key(userId, 'address'), value.address);
      if (value.latitude != null) {
        await prefs.setDouble(_key(userId, 'latitude'), value.latitude!);
      } else {
        await prefs.remove(_key(userId, 'latitude'));
      }
      if (value.longitude != null) {
        await prefs.setDouble(_key(userId, 'longitude'), value.longitude!);
      } else {
        await prefs.remove(_key(userId, 'longitude'));
      }
      if (value.accuracy != null) {
        await prefs.setDouble(_key(userId, 'accuracy'), value.accuracy!);
      } else {
        await prefs.remove(_key(userId, 'accuracy'));
      }
    } catch (_) {
      // Gagal menyimpan alamat tidak boleh menghalangi pesanan.
    }
  }
}
