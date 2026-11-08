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

    return CartItem(
      id: int.tryParse('${json['id']}') ?? 0,
      produkId: int.tryParse('${json['produk_id'] ?? produk['id']}') ?? 0,
      nama: '${produk['nama'] ?? json['nama'] ?? 'Produk Pertanian'}',
      harga: int.tryParse('${produk['harga'] ?? json['harga'] ?? 0}') ?? 0,
      jumlah: int.tryParse('${json['jumlah'] ?? 1}') ?? 1,
      stok: int.tryParse('${produk['stok'] ?? json['stok'] ?? 0}') ?? 0,
      satuanJual: '${produk['satuan_jual'] ?? json['satuan_jual'] ?? 'kg'}',
      mudahRusak: isMudahRusak,
      foto: produk['foto']?.toString() ?? json['foto']?.toString(),
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
