import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime time;
  final String type; // 'order', 'promo', 'info'
  final int? orderId;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.type = 'order',
    this.orderId,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'time': time.toIso8601String(),
        'type': type,
        'orderId': orderId,
        'isRead': isRead,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> json) =>
      AppNotificationItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
        type: json['type']?.toString() ?? 'order',
        orderId: json['orderId'] != null ? int.tryParse('${json['orderId']}') : null,
        isRead: json['isRead'] == true,
      );
}

/// Service notifikasi reaktif terpusat untuk AgriMart.
/// Menggunakan ValueNotifier agar badge bertambah secara instan
/// di seluruh layar tanpa memerlukan reload atau refresh halaman.
class NotificationService {
  static const String _storageKey = 'agrimart_notifications_v1';

  static final List<AppNotificationItem> _notifications = [];

  /// ValueNotifier untuk jumlah notifikasi belum dibaca (Unread)
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  /// ValueNotifier untuk jumlah pesanan aktif/baru
  static final ValueNotifier<int> newOrdersCountNotifier = ValueNotifier<int>(0);

  /// ValueNotifier untuk jumlah item dalam keranjang
  static final ValueNotifier<int> cartCountNotifier = ValueNotifier<int>(0);

  static List<AppNotificationItem> get notifications =>
      List.unmodifiable(_notifications);

  /// Inisialisasi data notifikasi dari penyimpanan lokal
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        _notifications.clear();
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _notifications.add(AppNotificationItem.fromJson(item));
          }
        }
      }
      _updateUnreadCount();
    } catch (_) {}
  }

  /// Tambah notifikasi pesanan baru seketika saat Checkout berhasil
  static void addOrderNotification(Order order) {
    final newItem = AppNotificationItem(
      id: 'notif_order_${order.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Pesanan #${order.id} Berhasil Dibuat! 🎉',
      message:
          'Pesanan atas nama ${order.namaPenerima} senilai Rp ${order.totalHarga} telah diterima dan sedang diproses toko.',
      time: DateTime.now(),
      type: 'order',
      orderId: order.id,
      isRead: false,
    );

    // Sisipkan di posisi teratas
    _notifications.insert(0, newItem);

    // Update notifiers seketika (Reaktif)
    _updateUnreadCount();
    newOrdersCountNotifier.value++;
    cartCountNotifier.value = 0; // Keranjang otomatis kosong setelah checkout

    _saveToStorage();
  }

  /// Tandai semua notifikasi sudah dibaca
  static void markAllAsRead() {
    for (final notif in _notifications) {
      notif.isRead = true;
    }
    _updateUnreadCount();
    _saveToStorage();
  }

  /// Tandai satu notifikasi sudah dibaca
  static void markAsRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      _updateUnreadCount();
      _saveToStorage();
    }
  }

  /// Hapus semua notifikasi
  static void clearAll() {
    _notifications.clear();
    _updateUnreadCount();
    _saveToStorage();
  }

  static void _updateUnreadCount() {
    final unread = _notifications.where((n) => !n.isRead).length;
    unreadCountNotifier.value = unread;
  }

  static Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
