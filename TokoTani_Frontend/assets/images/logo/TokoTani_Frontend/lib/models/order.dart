import 'courier.dart';
import 'payment_method.dart';
import 'product.dart';

class OrderModel {
  final int id;
  final String namaPenerima;
  final String alamatPenerima;
  final int kurirId;
  final Courier? courier;
  final int paymentMethodId;
  final PaymentMethod? paymentMethod;
  final int subtotal;
  final int ongkir;
  final int totalHarga;
  final String status;
  final String tanggalAntar;
  final String? createdAt;
  final String? idempotencyKey;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.namaPenerima,
    required this.alamatPenerima,
    required this.kurirId,
    this.courier,
    required this.paymentMethodId,
    this.paymentMethod,
    required this.subtotal,
    required this.ongkir,
    required this.totalHarga,
    required this.status,
    required this.tanggalAntar,
    this.createdAt,
    this.idempotencyKey,
    this.items = const [],
  });

  OrderModel copyWith({
    String? status,
    Courier? courier,
    PaymentMethod? paymentMethod,
  }) =>
      OrderModel(
        id: id,
        namaPenerima: namaPenerima,
        alamatPenerima: alamatPenerima,
        kurirId: kurirId,
        courier: courier ?? this.courier,
        paymentMethodId: paymentMethodId,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        subtotal: subtotal,
        ongkir: ongkir,
        totalHarga: totalHarga,
        status: status ?? this.status,
        tanggalAntar: tanggalAntar,
        createdAt: createdAt,
        idempotencyKey: idempotencyKey,
        items: items,
      );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': id,
      'nama_penerima': namaPenerima,
      'alamat_penerima': alamatPenerima,
      'kurir_id': kurirId,
      'payment_method_id': paymentMethodId,
      'subtotal': subtotal,
      'ongkir': ongkir,
      'total_harga': totalHarga,
      'status': status,
      'tanggal_antar': tanggalAntar,
      'created_at': createdAt,
      'idempotency_key': idempotencyKey,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final courierData = json['courier'] ?? json['kurir'];
    final paymentData = json['payment_method'] ?? json['metode_pembayaran'];

    final rawItems = json['items'] ?? json['order_items'] ?? [];
    final itemsList = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((e) => OrderItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <OrderItemModel>[];

    return OrderModel(
      id: int.tryParse('${json['id']}') ?? 0,
      namaPenerima: '${json['nama_penerima'] ?? ''}',
      alamatPenerima: '${json['alamat_penerima'] ?? ''}',
      kurirId: int.tryParse('${json['kurir_id'] ?? 0}') ?? 0,
      courier: courierData is Map
          ? Courier.fromJson(Map<String, dynamic>.from(courierData))
          : null,
      paymentMethodId: int.tryParse('${json['payment_method_id'] ?? 0}') ?? 0,
      paymentMethod: paymentData is Map
          ? PaymentMethod.fromJson(Map<String, dynamic>.from(paymentData))
          : null,
      subtotal: int.tryParse('${json['subtotal'] ?? 0}') ?? 0,
      ongkir: int.tryParse('${json['ongkir'] ?? 0}') ?? 0,
      totalHarga: int.tryParse('${json['total_harga'] ?? 0}') ?? 0,
      status: '${json['status'] ?? ''}'.trim().toLowerCase(),
      tanggalAntar: '${json['tanggal_antar'] ?? ''}',
      createdAt: json['created_at']?.toString(),
      idempotencyKey: json['idempotency_key']?.toString(),
      items: itemsList,
    );
  }
}

class OrderItemModel {
  final int id;
  final int orderId;
  final int productId;
  final String namaProduk;
  final int quantity;
  final int hargaSatuan;
  final int subtotal;
  final String? fotoProduk;
  final Product? product;

  const OrderItemModel({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.namaProduk,
    required this.quantity,
    required this.hargaSatuan,
    required this.subtotal,
    this.fotoProduk,
    this.product,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'harga_satuan': hargaSatuan,
      'subtotal': subtotal,
    };
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    final produk = json['product'] ?? json['produk'];
    final namaProduk = produk is Map
        ? '${produk['nama'] ?? json['nama'] ?? 'Produk'}'
        : '${json['nama'] ?? 'Produk'}';
    final foto = produk is Map ? produk['foto']?.toString() : null;

    return OrderItemModel(
      id: int.tryParse('${json['id']}') ?? 0,
      orderId: int.tryParse('${json['order_id'] ?? 0}') ?? 0,
      productId: int.tryParse('${json['product_id'] ?? 0}') ?? 0,
      namaProduk: namaProduk,
      quantity: int.tryParse('${json['quantity'] ?? 1}') ?? 1,
      hargaSatuan: int.tryParse('${json['harga_satuan'] ?? 0}') ?? 0,
      subtotal: int.tryParse('${json['subtotal'] ?? 0}') ?? 0,
      fotoProduk: foto,
      product: produk is Map
          ? Product.fromJson(Map<String, dynamic>.from(produk))
          : null,
    );
  }
}
