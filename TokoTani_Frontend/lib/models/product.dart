class Product {
  final int id;
  final String nama;
  final int harga;
  final String kategori;
  final int stok;
  final bool tersedia;
  final String? deskripsi;
  final String satuanJual;
  final bool mudahRusak;
  final String? foto;

  const Product({
    required this.id,
    required this.nama,
    required this.harga,
    required this.kategori,
    required this.stok,
    required this.tersedia,
    this.deskripsi,
    required this.satuanJual,
    required this.mudahRusak,
    this.foto,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawTersedia = json['tersedia'];
    final isTersedia = rawTersedia == null
        ? true
        : (rawTersedia == true || rawTersedia == 1 || '$rawTersedia' == '1' || '$rawTersedia'.toLowerCase() == 'true');

    final rawMudahRusak = json['mudah_rusak'];
    final isMudahRusak = rawMudahRusak == true ||
        rawMudahRusak == 1 ||
        '$rawMudahRusak' == '1' ||
        '$rawMudahRusak'.toLowerCase() == 'true';

    final foto = (json['foto'] ??
            json['gambar_url'] ??
            json['image_url'] ??
            json['gambar'])
        ?.toString();

    return Product(
      id: int.tryParse('${json['id']}') ?? 0,
      nama: '${json['nama'] ?? ''}',
      harga: int.tryParse('${json['harga'] ?? 0}') ?? 0,
      kategori: '${json['kategori'] ?? 'Umum'}',
      stok: int.tryParse('${json['stok'] ?? 0}') ?? 0,
      tersedia: isTersedia,
      deskripsi: json['deskripsi']?.toString(),
      satuanJual: '${json['satuan_jual'] ?? 'kg'}',
      mudahRusak: isMudahRusak,
      foto: foto,
    );
  }

  /// Dapat dibeli: tersedia menurut server dan stok masih ada.
  bool get isAvailable => tersedia && stok > 0;

  Map<String, dynamic> toJson() => {
    'nama': nama,
    'harga': harga,
    'kategori': kategori,
    'stok': stok,
    'tersedia': tersedia ? 1 : 0,
    'deskripsi': deskripsi,
    'satuan_jual': satuanJual,
    'mudah_rusak': mudahRusak ? 1 : 0,
    if (foto != null && foto!.isNotEmpty) 'foto': foto,
  };
}
