/// Pemetaan aset gambar terpusat untuk aplikasi Tani Mart.
/// Memastikan setiap foto produk dapat diganti secara independen oleh pengguna di assets/images/products/.
class ProductImages {
  // Logo
  static const String logo = 'assets/images/logo/agrimart_logo.png';

  // Banners
  static const String bannerPromo = 'assets/images/banners/banner_promo.jpg';
  static const String bannerPertanian = 'assets/images/banners/banner_pertanian.jpg';

  // Categories
  static const String catSayuran = 'assets/images/categories/sayuran.png';
  static const String catBuah = 'assets/images/categories/buah.png';
  static const String catBibit = 'assets/images/categories/bibit.png';
  static const String catPupuk = 'assets/images/categories/pupuk.png';
  static const String catAlatPertanian = 'assets/images/categories/alat_pertanian.png';
  static const String catKebutuhanHarian = 'assets/images/categories/kebutuhan_harian.png';

  // Products
  static const String beras = 'assets/images/products/beras_premium.jpg';
  static const String minyak = 'assets/images/products/minyak_goreng.jpg';
  static const String telur = 'assets/images/products/telur_ayam.jpg';
  static const String bibitCabai = 'assets/images/products/bibit_cabai.jpg';
  static const String pupukOrganik = 'assets/images/products/pupuk_organik.jpg';
  static const String tomat = 'assets/images/products/tomat.jpg';
  static const String bayam = 'assets/images/products/bayam.jpg';
  static const String jagung = 'assets/images/products/jagung.jpg';
  static const String alatPenyiram = 'assets/images/products/alat_penyiram.jpg';
  static const String kangkung = 'assets/images/products/kangkung.jpg';
  static const String cabaiRawit = 'assets/images/products/cabai_rawit.jpg';
  static const String kentang = 'assets/images/products/kentang.jpg';
  static const String wortel = 'assets/images/products/wortel.jpg';
  static const String bawangMerah = 'assets/images/products/bawang_merah.jpg';
  static const String gula = 'assets/images/products/gula_pasir.jpg';
  static const String terigu = 'assets/images/products/tepung_terigu.jpg';

  /// Pemetaan cerdas dari nama produk atau kategori ke aset gambar lokal
  static String getProductAsset(String? productName, {String? category}) {
    final name = (productName ?? '').toLowerCase();
    final cat = (category ?? '').toLowerCase();

    // Berdasarkan Nama Produk
    if (name.contains('beras')) return beras;
    if (name.contains('minyak')) return minyak;
    if (name.contains('telur')) return telur;
    if (name.contains('bayam')) return bayam;
    if (name.contains('kangkung')) return kangkung;
    if (name.contains('tomat')) return tomat;
    if (name.contains('cabai rawit')) return cabaiRawit;
    if (name.contains('bibit cabai') || (name.contains('bibit') && name.contains('cabai'))) return bibitCabai;
    if (name.contains('kentang')) return kentang;
    if (name.contains('wortel')) return wortel;
    if (name.contains('bawang')) return bawangMerah;
    if (name.contains('gula')) return gula;
    if (name.contains('terigu') || name.contains('tepung')) return terigu;
    if (name.contains('jagung')) return jagung;
    if (name.contains('penyiram') || name.contains('alat')) return alatPenyiram;
    if (name.contains('pupuk')) return pupukOrganik;

    // Berdasarkan Kategori jika nama spesifik belum cocok
    if (cat.contains('sayur')) return bayam;
    if (cat.contains('buah')) return tomat;
    if (cat.contains('bibit') || cat.contains('benih')) return bibitCabai;
    if (cat.contains('pupuk')) return pupukOrganik;
    if (cat.contains('alat')) return alatPenyiram;
    if (cat.contains('sembako') || cat.contains('harian')) return beras;

    return bayam; // Default fallback asset
  }

  /// Pemetaan nama kategori ke aset gambar kategori
  static String getCategoryAsset(String? categoryName) {
    final cat = (categoryName ?? '').toLowerCase();
    if (cat.contains('sayur')) return catSayuran;
    if (cat.contains('buah')) return catBuah;
    if (cat.contains('bibit') || cat.contains('benih')) return catBibit;
    if (cat.contains('pupuk')) return catPupuk;
    if (cat.contains('alat')) return catAlatPertanian;
    return catKebutuhanHarian;
  }
}

