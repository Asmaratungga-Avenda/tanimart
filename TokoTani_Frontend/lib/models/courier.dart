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

  /// Memeriksa apakah kurir bebas biaya / gratis ongkir.
  bool get isGratisOngkir => tarif == 0;

  factory Courier.fromJson(Map<String, dynamic> json) {
    final rawAktif = json['aktif'];
    final isAktif =
        rawAktif == true ||
        rawAktif == 1 ||
        '$rawAktif' == '1' ||
        '$rawAktif'.toLowerCase() == 'true';

    final nama = '${json['nama'] ?? ''}'.trim();
    final tarif = (int.tryParse('${json['tarif'] ?? 0}') ?? 0).clamp(0, 2147483647);

    return Courier(
      id: int.tryParse('${json['id']}') ?? 0,
      nama: nama,
      tarif: tarif,
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
