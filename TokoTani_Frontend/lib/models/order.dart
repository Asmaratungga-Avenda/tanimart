class Order {
  final int id;
  final String namaPenerima;
  final String alamatPenerima;
  final int kurirId;
  final String? namaCourier;
  final int paymentMethodId;
  final String? namaPaymentMethod;
  final int subtotal;
  final int ongkir;
  final int totalHarga;
  final String status;
  final String tanggalAntar;
  final String? createdAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.namaPenerima,
    required this.alamatPenerima,
    required this.kurirId,
    this.namaCourier,
    required this.paymentMethodId,
    this.namaPaymentMethod,
    required this.subtotal,
    required this.ongkir,
    required this.totalHarga,
    required this.status,
    required this.tanggalAntar,
    this.createdAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final courierData = json['courier'] ?? json['kurir'];
    final paymentData = json['payment_method'] ?? json['metode_pembayaran'];

    final rawItems = json['items'] ?? json['order_items'] ?? [];
    final itemsList = rawItems is List
        ? rawItems.map((e) => OrderItem.fromJson(Map<String, dynamic>.from(e))).toList()
        : <OrderItem>[];

    return Order(
      id: int.tryParse('${json['id']}') ?? 0,
      namaPenerima: '${json['nama_penerima'] ?? ''}',
      alamatPenerima: '${json['alamat_penerima'] ?? ''}',
      kurirId: int.tryParse('${json['kurir_id'] ?? 0}') ?? 0,
      namaCourier: courierData is Map ? '${courierData['nama'] ?? ''}' : null,
      paymentMethodId: int.tryParse('${json['payment_method_id'] ?? 0}') ?? 0,
      namaPaymentMethod: paymentData is Map ? '${paymentData['nama'] ?? ''}' : null,
      subtotal: int.tryParse('${json['subtotal'] ?? 0}') ?? 0,
      ongkir: int.tryParse('${json['ongkir'] ?? 0}') ?? 0,
      totalHarga: int.tryParse('${json['total_harga'] ?? 0}') ?? 0,
      status: '${json['status'] ?? 'menunggu_pembayaran'}',
      tanggalAntar: '${json['tanggal_antar'] ?? ''}',
      createdAt: json['created_at']?.toString(),
      items: itemsList,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String namaProduk;
  final int quantity;
  final int hargaSatuan;
  final int subtotal;
  final String? fotoProduk;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.namaProduk,
    required this.quantity,
    required this.hargaSatuan,
    required this.subtotal,
    this.fotoProduk,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final produk = json['product'] ?? json['produk'];
    final namaProduk = produk is Map
        ? '${produk['nama'] ?? json['nama'] ?? 'Produk'}'
        : '${json['nama'] ?? 'Produk'}';
    final foto = produk is Map ? produk['foto']?.toString() : null;

    return OrderItem(
      id: int.tryParse('${json['id']}') ?? 0,
      orderId: int.tryParse('${json['order_id'] ?? 0}') ?? 0,
      productId: int.tryParse('${json['product_id'] ?? 0}') ?? 0,
      namaProduk: namaProduk,
      quantity: int.tryParse('${json['quantity'] ?? 1}') ?? 1,
      hargaSatuan: int.tryParse('${json['harga_satuan'] ?? 0}') ?? 0,
      subtotal: int.tryParse('${json['subtotal'] ?? 0}') ?? 0,
      fotoProduk: foto,
    );
  }
}

