class CartItem {
  final int id; // ID baris keranjang di database backend
  final int produkId;
  final String nama;
  final int harga;
  final int jumlah;
  final int stok;
  final String satuanJual;
  final bool mudahRusak;
  final String? foto;

  const CartItem({
    required this.id,
    required this.produkId,
    required this.nama,
    required this.harga,
    required this.jumlah,
    required this.stok,
    required this.satuanJual,
    this.mudahRusak = false,
    this.foto,
  });

  /// Menghitung subtotal harga item (harga * jumlah).
  int get subtotal => harga * jumlah;

  /// Memeriksa apakah stok produk habis.
  bool get isOutOfStock => stok <= 0;

  /// Memeriksa apakah stok masih mencukupi untuk jumlah yang diinginkan.
  bool get hasSufficientStock => stok >= jumlah && stok > 0;

  /// Salinan objek CartItem dengan pembaruan nilai tertentu.
  CartItem copyWith({
    int? id,
    int? produkId,
    String? nama,
    int? harga,
    int? jumlah,
    int? stok,
    String? satuanJual,
    bool? mudahRusak,
    String? foto,
  }) {
    return CartItem(
      id: id ?? this.id,
      produkId: produkId ?? this.produkId,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      jumlah: jumlah ?? this.jumlah,
      stok: stok ?? this.stok,
      satuanJual: satuanJual ?? this.satuanJual,
      mudahRusak: mudahRusak ?? this.mudahRusak,
      foto: foto ?? this.foto,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Mendukung respons dengan objek produk bersarang (relasi Eloquent) maupun kolom rata
    final produk = json['produk'] is Map
        ? Map<String, dynamic>.from(json['produk'])
        : json;

    final rawMudahRusak = produk['mudah_rusak'] ?? json['mudah_rusak'];
    final isMudahRusak = rawMudahRusak == true ||
        rawMudahRusak == 1 ||
        '$rawMudahRusak' == '1' ||
        '$rawMudahRusak'.toLowerCase() == 'true';

    final foto = (produk['foto'] ??
            produk['gambar_url'] ??
            produk['image_url'] ??
            produk['gambar'] ??
            json['foto'] ??
            json['gambar_url'] ??
            json['image_url'] ??
            json['gambar'])
        ?.toString();

    final nama = '${produk['nama'] ?? json['nama'] ?? 'Produk Pertanian'}'.trim();
    final harga = (int.tryParse('${produk['harga'] ?? json['harga'] ?? 0}') ?? 0).clamp(0, 2147483647);
    final jumlah = (int.tryParse('${json['jumlah'] ?? 1}') ?? 1).clamp(1, 2147483647);
    final stok = (int.tryParse('${produk['stok'] ?? json['stok'] ?? 0}') ?? 0).clamp(0, 2147483647);
    final satuanJual = '${produk['satuan_jual'] ?? json['satuan_jual'] ?? 'kg'}'.trim();

    return CartItem(
      id: int.tryParse('${json['id']}') ?? 0,
      produkId: int.tryParse('${json['produk_id'] ?? produk['id']}') ?? 0,
      nama: nama.isEmpty ? 'Produk Pertanian' : nama,
      harga: harga,
      jumlah: jumlah,
      stok: stok,
      satuanJual: satuanJual.isEmpty ? 'kg' : satuanJual,
      mudahRusak: isMudahRusak,
      foto: foto,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'produk_id': produkId,
    'nama': nama,
    'harga': harga,
    'jumlah': jumlah,
    'stok': stok,
    'satuan_jual': satuanJual,
    'mudah_rusak': mudahRusak ? 1 : 0,
    if (foto != null) 'foto': foto,
  };
}
