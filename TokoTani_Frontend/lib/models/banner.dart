class BannerModel {
  final int id;
  final String judul;
  final String? gambar;
  final String url;
  final String? link;
  final int urutan;
  final bool aktif;

  const BannerModel({
    required this.id,
    required this.judul,
    this.gambar,
    required this.url,
    this.link,
    required this.urutan,
    required this.aktif,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: int.tryParse('${json['id']}') ?? 0,
      judul: '${json['judul'] ?? ''}',
      gambar: json['gambar']?.toString(),
      url: '${json['url'] ?? ''}',
      link: json['link']?.toString(),
      urutan: int.tryParse('${json['urutan']}') ?? 0,
      aktif: json['aktif'] == true || json['aktif'] == 1 || '${json['aktif']}' == '1',
    );
  }
}
