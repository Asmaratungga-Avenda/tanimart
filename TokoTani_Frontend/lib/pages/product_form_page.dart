import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/responsive_wrapper.dart';

class ProductFormPage extends StatefulWidget {
  final Product? product;

  const ProductFormPage({super.key, this.product});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController namaCtrl;
  late final TextEditingController hargaCtrl;
  late final TextEditingController kategoriCtrl;
  late final TextEditingController stokCtrl;
  late final TextEditingController deskripsiCtrl;
  late final TextEditingController satuanCtrl;
  late final TextEditingController fotoCtrl;

  bool tersedia = true;
  bool mudahRusak = false;
  bool saving = false;

  // Penampung galat validasi 422 per kolom dari server (Sesuai Kriteria 6)
  Map<String, String> fieldErrors = {};

  bool get isEdit => widget.product != null;

  final List<String> kategoriSuggestions = const [
    'Sayuran',
    'Bumbu & Rempah',
    'Beras & Biji-bijian',
    'Buah-buahan',
    'Umbi-umbian',
    'Lainnya',
  ];

  final List<String> satuanSuggestions = const [
    'kg',
    'ikat',
    'pak',
    'liter',
    'gram',
    'butir',
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    namaCtrl = TextEditingController(text: p?.nama ?? '');
    hargaCtrl = TextEditingController(text: p != null ? p.harga.toString() : '');
    kategoriCtrl = TextEditingController(text: p?.kategori ?? 'Sayuran');
    stokCtrl = TextEditingController(text: p != null ? p.stok.toString() : '10');
    deskripsiCtrl = TextEditingController(text: p?.deskripsi ?? '');
    satuanCtrl = TextEditingController(text: p?.satuanJual ?? 'kg');
    fotoCtrl = TextEditingController(text: p?.foto ?? '');
    tersedia = p?.tersedia ?? true;
    mudahRusak = p?.mudahRusak ?? false;
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    hargaCtrl.dispose();
    kategoriCtrl.dispose();
    stokCtrl.dispose();
    deskripsiCtrl.dispose();
    satuanCtrl.dispose();
    fotoCtrl.dispose();
    super.dispose();
  }

  void _clearFieldError(String fieldName) {
    if (fieldErrors.containsKey(fieldName)) {
      setState(() {
        fieldErrors.remove(fieldName);
      });
    }
  }

  Future<void> save() async {
    // Validasi form sisi klien terlebih dahulu
    if (!formKey.currentState!.validate()) return;

    setState(() {
      saving = true;
      fieldErrors.clear();
    });

    final payload = {
      'nama': namaCtrl.text.trim(),
      'harga': int.parse(hargaCtrl.text.trim()),
      'kategori': kategoriCtrl.text.trim(),
      'stok': int.parse(stokCtrl.text.trim()),
      'tersedia': tersedia,
      'deskripsi': deskripsiCtrl.text.trim().isEmpty ? null : deskripsiCtrl.text.trim(),
      'satuan_jual': satuanCtrl.text.trim(),
      'mudah_rusak': mudahRusak,
      if (fotoCtrl.text.trim().isNotEmpty) 'foto': fotoCtrl.text.trim(),
    };

    try {
      if (isEdit) {
        await ApiService.updateProduct(widget.product!.id, payload);
      } else {
        await ApiService.createProduct(payload);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            isEdit
                ? 'Produk "${payload['nama']}" berhasil diperbarui.'
                : 'Produk "${payload['nama']}" berhasil ditambahkan.',
          ),
        ),
      );

      // Kembali ke halaman kelola produk dengan status berhasil (true)
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;

      // Kriteria 6: Tampilkan pesan galat 422 tepat di bawah masing-masing kolom!
      if (e.errorType == ApiErrorType.validation || e.statusCode == 422) {
        setState(() {
          fieldErrors = e.fieldErrors;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    e.message.isNotEmpty
                        ? e.message
                        : 'Validasi gagal. Periksa kolom yang bertanda merah.',
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Tampilkan pesan galat lainnya (koneksi, timeout, 500)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text(e.message),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Terjadi kesalahan jaringan atau server.'),
        ),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Ubah Produk Pertanian' : 'Tambah Produk Pertanian'),
      ),
      body: ResponsiveScrollWrapper(
        child: Form(
          key: formKey,
          child: ListView(
            // ignore: deprecated_member_use
            cacheExtent: 2000.0,
            padding: const EdgeInsets.all(16),
          children: [
            // Nama Produk
            TextFormField(
              controller: namaCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Produk Pertanian *',
                hintText: 'Contoh: Cabai Merah Keriting',
                prefixIcon: const Icon(Icons.eco, color: Color(0xFF2E7D32)),
                errorText: fieldErrors['nama'],
              ),
              onChanged: (_) => _clearFieldError('nama'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Nama produk wajib diisi.';
                if (v.trim().length < 3) return 'Nama produk minimal 3 karakter.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Kategori
            TextFormField(
              controller: kategoriCtrl,
              decoration: InputDecoration(
                labelText: 'Kategori Produk *',
                hintText: 'Sayuran / Buah / Beras',
                prefixIcon: const Icon(Icons.category, color: Color(0xFF2E7D32)),
                errorText: fieldErrors['kategori'],
                suffixIcon: PopupMenuButton<String>(
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                  tooltip: 'Pilih saran kategori',
                  onSelected: (val) {
                    setState(() {
                      kategoriCtrl.text = val;
                      _clearFieldError('kategori');
                    });
                  },
                  itemBuilder: (_) => kategoriSuggestions
                      .map((k) => PopupMenuItem(value: k, child: Text(k)))
                      .toList(),
                ),
              ),
              onChanged: (_) => _clearFieldError('kategori'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Kategori wajib diisi.' : null,
            ),
            const SizedBox(height: 8),
            // Quick suggestion chips untuk Kategori
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: kategoriSuggestions.map((cat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(cat, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        setState(() {
                          kategoriCtrl.text = cat;
                          _clearFieldError('kategori');
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Harga dan Satuan Jual (Khas Pertanian)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: hargaCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Harga (Rp) *',
                      hintText: 'Contoh: 25000',
                      prefixText: 'Rp ',
                      errorText: fieldErrors['harga'],
                    ),
                    onChanged: (_) => _clearFieldError('harga'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Harga wajib diisi.';
                      final num = int.tryParse(v.trim());
                      if (num == null || num <= 0) return 'Harga harus berupa angka bulat positif.';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: satuanCtrl,
                    decoration: InputDecoration(
                      labelText: 'Satuan Jual *',
                      hintText: 'kg / ikat / pak',
                      errorText: fieldErrors['satuan_jual'],
                      suffixIcon: PopupMenuButton<String>(
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                        tooltip: 'Pilih saran satuan',
                        onSelected: (val) {
                          setState(() {
                            satuanCtrl.text = val;
                            _clearFieldError('satuan_jual');
                          });
                        },
                        itemBuilder: (_) => satuanSuggestions
                            .map((s) => PopupMenuItem(value: s, child: Text(s)))
                            .toList(),
                      ),
                    ),
                    onChanged: (_) => _clearFieldError('satuan_jual'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Satuan wajib diisi.' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick suggestion chips untuk Satuan
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: satuanSuggestions.map((sat) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(sat, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () {
                        setState(() {
                          satuanCtrl.text = sat;
                          _clearFieldError('satuan_jual');
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),

            // Stok
            TextFormField(
              controller: stokCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah Stok Tersedia *',
                hintText: '0 untuk stok habis',
                prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2E7D32)),
                errorText: fieldErrors['stok'],
              ),
              onChanged: (_) => _clearFieldError('stok'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Stok wajib diisi.';
                final num = int.tryParse(v.trim());
                if (num == null || num < 0) return 'Stok harus berupa angka 0 atau lebih.';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Deskripsi (Boleh null)
            TextFormField(
              controller: deskripsiCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Deskripsi Produk (Opsional)',
                hintText: 'Keterangan mutu panen, cara simpan, dll.',
                prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF64748B)),
                errorText: fieldErrors['deskripsi'],
              ),
              onChanged: (_) => _clearFieldError('deskripsi'),
            ),
            const SizedBox(height: 14),

            // Foto Produk (Opsional / fallback ke aset lokal)
            TextFormField(
              controller: fotoCtrl,
              decoration: const InputDecoration(
                labelText: 'URL Foto Produk (Opsional)',
                hintText: 'https://domain.com/foto_produk.jpg',
                prefixIcon: Icon(Icons.image_outlined, color: Color(0xFF64748B)),
                helperText: 'Kosongkan untuk otomatis menggunakan aset foto lokal AgriMart',
                helperStyle: TextStyle(fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),

            // Atribut Khas Domain Pertanian: Mudah Rusak
            Material(
              color: Colors.orange.shade50.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.orange.shade200),
              ),
              child: SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time_rounded, color: Colors.orange.shade900, size: 20),
                ),
                title: const Text(
                  'Produk Mudah Rusak (Perishable)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'Wajib dikirim di hari yang sama karena masa simpan singkat.',
                  style: TextStyle(fontSize: 12),
                ),
                value: mudahRusak,
                activeThumbColor: const Color(0xFF2E7D32),
                onChanged: (v) => setState(() => mudahRusak = v),
              ),
            ),
            const SizedBox(height: 10),

            // Status Ketersediaan
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: tersedia ? const Color(0xFFE8F5E9) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tersedia ? Icons.check_circle_rounded : Icons.cancel_outlined,
                    color: tersedia ? const Color(0xFF2E7D32) : Colors.grey,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Produk Aktif / Tersedia',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  tersedia
                      ? 'Produk tampil di katalog dan dapat dipesan.'
                      : 'Produk disembunyikan sementara dari pembeli.',
                  style: const TextStyle(fontSize: 12),
                ),
                value: tersedia,
                activeThumbColor: const Color(0xFF2E7D32),
                onChanged: (v) => setState(() => tersedia = v),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan (Dinonaktifkan saat saving untuk mencegah klik ganda)
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                icon: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(
                  saving
                      ? 'Menyimpan...'
                      : (isEdit ? 'Simpan Perubahan' : 'Simpan Produk'),
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: saving ? null : save,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
