class ProductModel {
  final int id;
  final String namaProduk;
  final int harga;
  final int stok;
  final String satuanJual;
  final bool mudahRusak;

  ProductModel({
    required this.id,
    required this.namaProduk,
    required this.harga,
    required this.stok,
    required this.satuanJual,
    required this.mudahRusak,
  });

  // Fungsi untuk mengubah JSON dari Laravel menjadi Objek Dart
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      namaProduk: json['nama_produk'] ?? '',
      harga: json['harga'] ?? 0,
      stok: json['stok'] ?? 0,
      satuanJual: json['satuan_jual'] ?? 'kg',
      mudahRusak: json['mudah_rusak'] == 1, // Mengubah tipe 1/0 dari database ke boolean true/false
    );
  }
}