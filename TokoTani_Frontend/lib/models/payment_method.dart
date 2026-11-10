class PaymentMethod {
  final int id;
  final String nama;
  final String? deskripsi;
  final bool aktif;

  const PaymentMethod({
    required this.id,
    required this.nama,
    this.deskripsi,
    this.aktif = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final rawAktif = json['aktif'];
    final isAktif =
        rawAktif == true ||
        rawAktif == 1 ||
        '$rawAktif' == '1' ||
        '$rawAktif'.toLowerCase() == 'true';

    final nama = '${json['nama'] ?? ''}'.trim();
    final deskripsi = json['deskripsi']?.toString().trim();

    return PaymentMethod(
      id: int.tryParse('${json['id']}') ?? 0,
      nama: nama,
      deskripsi: (deskripsi != null && deskripsi.isNotEmpty) ? deskripsi : null,
      aktif: isAktif,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nama': nama,
    'deskripsi': deskripsi,
    'aktif': aktif ? 1 : 0,
  };
}
