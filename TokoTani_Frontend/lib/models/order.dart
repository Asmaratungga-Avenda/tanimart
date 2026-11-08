import 'courier.dart';
import 'payment_method.dart';
import 'product.dart';

class OrderItemModel {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final int hargaSatuan;
  final int subtotal;
  final Product? product;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.hargaSatuan,
    required this.subtotal,
    this.product,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: int.tryParse('${json['id']}') ?? 0,
      orderId: int.tryParse('${json['order_id']}') ?? 0,
      productId: int.tryParse('${json['product_id']}') ?? 0,
      quantity: int.tryParse('${json['quantity']}') ?? 1,
      hargaSatuan: int.tryParse('${json['harga_satuan']}') ?? 0,
      subtotal: int.tryParse('${json['subtotal']}') ?? 0,
      product: json['product'] is Map ? Product.fromJson(Map<String, dynamic>.from(json['product'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'order_id': orderId,
    'product_id': productId,
    'quantity': quantity,
    'harga_satuan': hargaSatuan,
    'subtotal': subtotal,
  };
}

class OrderModel {
  final int id;
  final String namaPenerima;
  final String alamatPenerima;
  final int kurirId;
  final int paymentMethodId;
  final int subtotal;
  final int ongkir;
  final int totalHarga;
  final String status;
  final String tanggalAntar;
  final String? idempotencyKey;
  final String? createdAt;
  final List<OrderItemModel> items;
  final Courier? courier;
  final PaymentMethod? paymentMethod;

  const OrderModel({
    required this.id,
    required this.namaPenerima,
    required this.alamatPenerima,
    required this.kurirId,
    required this.paymentMethodId,
    required this.subtotal,
    required this.ongkir,
    required this.totalHarga,
    required this.status,
    required this.tanggalAntar,
    this.idempotencyKey,
    this.createdAt,
    this.items = const [],
    this.courier,
    this.paymentMethod,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] ?? json['order_items'] ?? [];
    final itemsList = rawItems is List
        ? rawItems.map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e))).toList()
        : <OrderItemModel>[];

    return OrderModel(
      id: int.tryParse('${json['id']}') ?? 0,
      namaPenerima: '${json['nama_penerima'] ?? ''}',
      alamatPenerima: '${json['alamat_penerima'] ?? ''}',
      kurirId: int.tryParse('${json['kurir_id']}') ?? 0,
      paymentMethodId: int.tryParse('${json['payment_method_id']}') ?? 0,
      subtotal: int.tryParse('${json['subtotal']}') ?? 0,
      ongkir: int.tryParse('${json['ongkir']}') ?? 0,
      totalHarga: int.tryParse('${json['total_harga']}') ?? 0,
      status: '${json['status'] ?? 'menunggu_pembayaran'}',
      tanggalAntar: '${json['tanggal_antar'] ?? ''}',
      idempotencyKey: json['idempotency_key']?.toString(),
      createdAt: json['created_at']?.toString(),
      items: itemsList,
      courier: json['courier'] is Map ? Courier.fromJson(Map<String, dynamic>.from(json['courier'])) : null,
      paymentMethod: json['payment_method'] is Map ? PaymentMethod.fromJson(Map<String, dynamic>.from(json['payment_method'])) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama_penerima': namaPenerima,
    'alamat_penerima': alamatPenerima,
    'kurir_id': kurirId,
    'payment_method_id': paymentMethodId,
    'subtotal': subtotal,
    'ongkir': ongkir,
    'total_harga': totalHarga,
    'status': status,
    'tanggal_antar': tanggalAntar,
    if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
  };
}

