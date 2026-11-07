class Courier {
  final int id;
  final String nama;
  final int tarif;
  final bool aktif;

  const Courier({
    required this.id,
    required this.nama,
    required this.tarif,
    required this.aktif,
  });

  factory Courier.fromJson(Map<String, dynamic> json) {
    final rawAktif = json['aktif'];
    final isAktif = rawAktif == true ||
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
}

