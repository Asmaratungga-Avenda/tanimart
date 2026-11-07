class PaymentMethod {
  final int id;
  final String nama;
  final String? deskripsi;
  final bool aktif;

  const PaymentMethod({
    required this.id,
    required this.nama,
    this.deskripsi,
    required this.aktif,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final rawAktif = json['aktif'];
    final isAktif = rawAktif == true ||
        rawAktif == 1 ||
        '$rawAktif' == '1' ||
        '$rawAktif'.toLowerCase() == 'true';

    return PaymentMethod(
      id: int.tryParse('${json['id']}') ?? 0,
      nama: '${json['nama'] ?? ''}',
      deskripsi: json['deskripsi']?.toString(),
      aktif: isAktif,
    );
  }
}

