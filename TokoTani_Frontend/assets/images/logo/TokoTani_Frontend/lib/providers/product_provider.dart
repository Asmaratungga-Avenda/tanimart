import 'package:flutter/foundation.dart';

import '../models/product.dart';
import '../services/api_service.dart';

enum ProductSort { none, priceAsc, priceDesc, name }

/// Katalog produk. Data dimuat sekali dari API; pencarian, filter kategori, dan
/// urutan dikerjakan di perangkat sehingga mengetik tidak memicu request berulang.
class ProductProvider extends ChangeNotifier {
  List<Product> _all = const [];
  List<String> _apiCategories = const [];
  List<String> _derivedCategories = const [];

  String _query = '';
  String? _category;
  ProductSort _sort = ProductSort.none;

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<Product>? _filteredCache;

  List<Product> get all => _all;
  String get query => _query;
  String? get category => _category;
  ProductSort get sort => _sort;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _all.isEmpty;
  bool get hasActiveFilter => _query.trim().isNotEmpty || _category != null;

  /// Kategori dari endpoint `/kategori`; bila tidak tersedia, diturunkan dari produk.
  List<String> get categories =>
      _apiCategories.isNotEmpty ? _apiCategories : _derivedCategories;

  List<Product> get filtered => _filteredCache ??= _applyFilter();

  /// Produk terbaru (id terbesar) yang masih bisa dibeli.
  List<Product> latest({int limit = 6}) {
    final list = _all.where((p) => p.isAvailable).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return list.take(limit).toList();
  }

  Future<void> ensureLoaded() {
    if (_hasLoaded || _isLoading) return Future<void>.value();
    return load();
  }

  /// Memuat produk dan kategori. Mengembalikan pesan galat bila gagal.
  Future<String?> load() async {
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? error;
    try {
      final productsFuture = ApiService.getProducts();
      final categoriesFuture = ApiService.getCategories().then<List<String>?>(
        (value) => value,
        onError: (Object _) => null,
      );
      final products = await productsFuture;
      final categories = await categoriesFuture;

      _all = products;
      _apiCategories = categories ?? const [];
      _derivedCategories = _deriveCategories(products);
      if (_category != null && !_hasCategory(_category!)) _category = null;
      _hasLoaded = true;
      _filteredCache = null;
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Produk belum dapat dimuat. Silakan coba lagi.';
    } finally {
      _errorMessage = error;
      _isLoading = false;
      notifyListeners();
    }
    return error;
  }

  bool _hasCategory(String name) => categories.any(
    (c) => c.toLowerCase() == name.toLowerCase(),
  );

  List<String> _deriveCategories(List<Product> products) {
    final seen = <String>{};
    final result = <String>[];
    for (final p in products) {
      final name = p.kategori.trim();
      if (name.isNotEmpty && seen.add(name.toLowerCase())) result.add(name);
    }
    return result;
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _filteredCache = null;
    notifyListeners();
  }

  void setCategory(String? value) {
    if (value == _category) return;
    _category = value;
    _filteredCache = null;
    notifyListeners();
  }

  /// Dipakai Beranda untuk membuka katalog dengan filter tertentu.
  void setFilter({String? category, String query = ''}) {
    _category = category;
    _query = query;
    _filteredCache = null;
    notifyListeners();
  }

  void setSort(ProductSort value) {
    if (value == _sort) return;
    _sort = value;
    _filteredCache = null;
    notifyListeners();
  }

  void clearFilter() => setFilter();

  /// Menyegarkan satu produk (misalnya stok terbaru dari halaman detail).
  void applyFresh(Product product) {
    final index = _all.indexWhere((p) => p.id == product.id);
    if (index == -1) return;
    final next = List<Product>.of(_all);
    next[index] = product;
    _all = next;
    _filteredCache = null;
    notifyListeners();
  }

  List<Product> _applyFilter() {
    final q = _query.trim().toLowerCase();
    final cat = _category?.toLowerCase();
    final result = _all.where((p) {
      if (cat != null && p.kategori.toLowerCase() != cat) return false;
      if (q.isEmpty) return true;
      return p.nama.toLowerCase().contains(q) ||
          p.kategori.toLowerCase().contains(q);
    }).toList();

    switch (_sort) {
      case ProductSort.priceAsc:
        result.sort((a, b) => a.harga.compareTo(b.harga));
      case ProductSort.priceDesc:
        result.sort((a, b) => b.harga.compareTo(a.harga));
      case ProductSort.name:
        result.sort(
          (a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()),
        );
      case ProductSort.none:
        break;
    }
    return result;
  }
}
