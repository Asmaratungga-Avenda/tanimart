class ProductCategory {
  final int? id;
  final String nama;
  final String? gambar;

  const ProductCategory({
    this.id,
    required this.nama,
    this.gambar,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: int.tryParse('${json['id'] ?? 0}'),
      nama: '${json['nama'] ?? json['nama_kategori'] ?? json['kategori'] ?? json['name'] ?? ''}',
      gambar: (json['gambar_url'] ?? json['gambar'])?.toString(),
    );
  }
}
