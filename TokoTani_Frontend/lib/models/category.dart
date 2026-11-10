class CategoryModel {
  final int id;
  final String nama;
  final String? gambar;
  final String? gambarUrl;

  const CategoryModel({
    required this.id,
    required this.nama,
    this.gambar,
    this.gambarUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: int.tryParse('${json['id']}') ?? 0,
      nama: '${json['nama_kategori'] ?? json['nama'] ?? ''}',
      gambar: json['gambar']?.toString(),
      gambarUrl: json['gambar_url'] ?? 
                 json['image_url'] ?? 
                 json['foto'] ?? 
                 json['image'] ?? 
                 json['gambar'],
    );
  }
}
