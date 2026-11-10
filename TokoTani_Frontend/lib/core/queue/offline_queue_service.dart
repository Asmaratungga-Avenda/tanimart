import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

/// Model satu item antrean offline.
class OfflineQueueItem {
  final String id;
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final String? localFilePath;
  final DateTime createdAt;
  int retryCount;
  final int maxRetries;
  String? lastError;
  final bool isMultipart;

  OfflineQueueItem({
    required this.id,
    required this.endpoint,
    required this.method,
    required this.payload,
    this.localFilePath,
    required this.createdAt,
    this.retryCount = 0,
    this.maxRetries = 5,
    this.lastError,
    this.isMultipart = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'endpoint': endpoint,
        'method': method,
        'payload': payload,
        'local_file_path': localFilePath,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
        'max_retries': maxRetries,
        'last_error': lastError,
        'is_multipart': isMultipart ? 1 : 0,
      };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: '${json['id']}',
      endpoint: '${json['endpoint']}',
      method: '${json['method']}',
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      localFilePath: json['local_file_path']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      retryCount: int.tryParse('${json['retry_count']}') ?? 0,
      maxRetries: int.tryParse('${json['max_retries']}') ?? 5,
      lastError: json['last_error']?.toString(),
      isMultipart: (json['is_multipart'] ?? 0) == 1,
    );
  }
}

/// Layanan antrean request offline berbasis Hive.
///
/// Request yang gagal karena tidak ada koneksi disimpan di sini dan
/// dicoba kembali saat koneksi pulih. Checkout/pembayaran tidak dimasukkan
/// ke antrean tanpa idempotency key yang benar.
class OfflineQueueService {
  OfflineQueueService._();
  static final OfflineQueueService instance = OfflineQueueService._();

  static const String _boxName = 'offline_queue';
  Box<OfflineQueueItem>? _box;

  bool get isReady => _box != null;

  Future<void> init() async {
    if (_box != null) return;
    await Hive.initFlutter();
    Hive.registerAdapter(OfflineQueueItemAdapter());
    _box = await Hive.openBox<OfflineQueueItem>(_boxName);
  }

  /// Tambah item ke antrean. Mencegah duplikasi berdasarkan endpoint + payload.
  Future<void> enqueue(OfflineQueueItem item) async {
    if (_box == null) return;
    final existing = _box!.values.firstWhere(
      (e) => e.endpoint == item.endpoint &&
          e.method == item.method &&
          _samePayload(e.payload, item.payload),
      orElse: () => OfflineQueueItem(
        id: '',
        endpoint: '',
        method: '',
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
    if (existing.id.isNotEmpty) return;
    await _box!.add(item);
  }

  /// Ambil semua item antrean yang belum melebihi max retries.
  Future<List<OfflineQueueItem>> getPending() async {
    if (_box == null) return [];
    return _box!.values
        .where((e) => e.retryCount < e.maxRetries)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// Tandai item berhasil dihapus dari antrean.
  Future<void> remove(String id) async {
    if (_box == null) return;
    final key = _box!.keys.firstWhere(
      (k) => _box!.get(k)?.id == id,
      orElse: () => -1 as dynamic,
    );
    if (key != -1) await _box!.delete(key);
  }

  /// Tandai gagal: increment retry count dan simpan error terakhir.
  Future<void> fail(String id, String error) async {
    if (_box == null) return;
    final key = _box!.keys.firstWhere(
      (k) => _box!.get(k)?.id == id,
      orElse: () => -1 as dynamic,
    );
    if (key == -1) return;
    final item = _box!.get(key);
    if (item == null) return;
    await _box!.put(key, OfflineQueueItem(
      id: item.id,
      endpoint: item.endpoint,
      method: item.method,
      payload: item.payload,
      localFilePath: item.localFilePath,
      createdAt: item.createdAt,
      retryCount: item.retryCount + 1,
      maxRetries: item.maxRetries,
      lastError: error,
      isMultipart: item.isMultipart,
    ));
  }

  /// Hapus semua item yang telah gagal maksimal (tidak akan dicoba lagi).
  Future<void> clearExpired() async {
    if (_box == null) return;
    final toDelete = <dynamic>[];
    for (final entry in _box!.toMap().entries) {
      final item = entry.value;
      if (item.retryCount >= item.maxRetries) {
        toDelete.add(entry.key);
      }
    }
    for (final key in toDelete) {
      await _box!.delete(key);
    }
  }

  Future<void> clearAll() async {
    if (_box == null) return;
    await _box!.clear();
  }

  int get length => _box?.length ?? 0;

  bool _samePayload(Map<String, dynamic> a, Map<String, dynamic> b) {
    const JsonEncoder esc = JsonEncoder.withIndent('');
    return esc.convert(a) == esc.convert(b);
  }
}

/// Hive TypeAdapter untuk OfflineQueueItem.
class OfflineQueueItemAdapter extends TypeAdapter<OfflineQueueItem> {
  @override
  final int typeId = 101;

  @override
  OfflineQueueItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numFields; i++) {
      fields[reader.readByte()] = reader.read();
    }
    return OfflineQueueItem(
      id: fields[0] as String,
      endpoint: fields[1] as String,
      method: fields[2] as String,
      payload: Map<String, dynamic>.from(fields[3] ?? {}),
      localFilePath: fields[4] as String?,
      createdAt: DateTime.parse(fields[5] as String),
      retryCount: fields[6] as int,
      maxRetries: fields[7] as int,
      lastError: fields[8] as String?,
      isMultipart: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineQueueItem obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.endpoint)
      ..writeByte(2)
      ..write(obj.method)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.localFilePath)
      ..writeByte(5)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(6)
      ..write(obj.retryCount)
      ..writeByte(7)
      ..write(obj.maxRetries)
      ..writeByte(8)
      ..write(obj.lastError)
      ..writeByte(9)
      ..write(obj.isMultipart);
  }
}
