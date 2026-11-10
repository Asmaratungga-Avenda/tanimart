class Courier {
  final int id;
  final String nama;
  final int tarif;
  final bool aktif;

  const Courier({
    required this.id,
    required this.nama,
    required this.tarif,
    this.aktif = true,
  });

  factory Courier.fromJson(Map<String, dynamic> json) {
    final rawAktif = json['aktif'];
    final isAktif =
        rawAktif == true ||
        rawAktif == 1 ||
        '$rawAktif' == '1' ||
        '$rawAktif'.toLowerCase() == 'true';

    return Courier(
      id: int.tryParse('${json['id']}') ?? 0,
      nama: '${json['nama'] ?? ''}',
      tarif: int.tryParse('${json['tarif'] ?? 0}') ?? 0,
      aktif: isAktif,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'tarif': tarif,
    'aktif': aktif ? 1 : 0,
  };
}
