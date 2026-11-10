import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/cache/hive_service.dart';
import '../models/category.dart' as category_model;
import '../models/product.dart';
import '../services/api_service.dart';

enum ProductSort { none, priceAsc, priceDesc, name }

/// Katalog produk dengan infinite scroll pagination dan strategi cache-first.
///
/// Alur muat:
/// 1. Tampilkan cache Hive terlebih dahulu (jika ada).
/// 2. Request ke Laravel di background (stale-while-revalidate).
/// 3. Simpan hasil terbaru ke Hive.
/// 4. Saat offline, tetap tampilkan cache terakhir.
class ProductProvider extends ChangeNotifier {
  List<Product> _all = const [];
  List<category_model.ProductCategory> _apiCategories = const [];
  List<category_model.ProductCategory> _derivedCategories = const [];

  String _query = '';
  String? _category;
  ProductSort _sort = ProductSort.none;

  // Pagination state
  int _currentPage = 1;
  final int _perPage = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _isInitialLoading = false;
  bool _hasLoaded = false;

  String? _errorMessage;
  String? _refreshError;
  final bool _isOffline = false;
  bool _isRefreshing = false;

  List<Product> get all => _all;
  String get query => _query;
  String? get category => _category;
  ProductSort get sort => _sort;
  bool get isLoading => _isInitialLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isRefreshing => _isRefreshing;
  bool get hasLoaded => _hasLoaded;
  String? get errorMessage => _errorMessage;
  String? get refreshError => _refreshError;
  bool get isEmpty => _all.isEmpty;
  bool get isOffline => _isOffline;
  bool get hasMore => _hasMore;
  bool get hasActiveFilter => _query.trim().isNotEmpty || _category != null;

  List<category_model.ProductCategory> get categories =>
      _apiCategories.isNotEmpty ? _apiCategories : _derivedCategories;

  List<Product> get filtered {
    final result = _all.where((p) {
      final cat = _category?.toLowerCase();
      if (cat != null && p.kategori.toLowerCase() != cat) return false;
      final q = _query.trim().toLowerCase();
      if (q.isNotEmpty) {
        return p.nama.toLowerCase().contains(q) ||
            p.kategori.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    switch (_sort) {
      case ProductSort.priceAsc:
        result.sort((a, b) => a.harga.compareTo(b.harga));
      case ProductSort.priceDesc:
        result.sort((a, b) => b.harga.compareTo(a.harga));
      case ProductSort.name:
        result.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      case ProductSort.none:
        break;
    }
    return result;
  }

  List<Product> latest({int limit = 6}) {
    final list = _all.where((p) => p.isAvailable).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    return list.take(limit).toList();
  }

  // -----------------------------------------------------------------------
  // PUBLIC API
  // -----------------------------------------------------------------------

  /// Muat data awal: cache dulu, lalu server. Dipakai saat pertama kali buka katalog.
  Future<void> ensureLoaded() async {
    if (_hasLoaded && !_isInitialLoading) return;
    await _loadFromCache();
    await _loadFromServer(page: 1, refresh: true);
  }

  /// Muat halaman berikutnya (infinite scroll). Tidak memicu request ganda.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    if (!_hasLoaded) return;
    await _loadFromServer(page: _currentPage + 1, refresh: false);
  }

  /// Tarik untuk segarkan (pull-to-refresh). Reset pagination.
  Future<String?> refresh() async {
    _isRefreshing = true;
    _refreshError = null;
    notifyListeners();
    String? error;
    try {
      await _loadFromServer(page: 1, refresh: true);
    } on ApiException catch (e) {
      error = e.message;
      _refreshError = e.message;
    } catch (_) {
      error = 'Produk belum dapat dimuat ulang. Silakan coba lagi.';
      _refreshError = error;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
    return error;
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _resetPagination();
    notifyListeners();
    unawaited(_loadFromServer(page: 1, refresh: true));
  }

  void setCategory(String? value) {
    if (value == _category) return;
    _category = value;
    _resetPagination();
    notifyListeners();
    unawaited(_loadFromServer(page: 1, refresh: true));
  }

  /// Dipakai Beranda untuk membuka katalog dengan filter tertentu.
  void setFilter({String? category, String query = ''}) {
    _category = category;
    _query = query;
    _resetPagination();
    notifyListeners();
    unawaited(_loadFromServer(page: 1, refresh: true));
  }

  void clearFilter() => setFilter();

  void setSort(ProductSort value) {
    if (value == _sort) return;
    _sort = value;
    notifyListeners();
  }

  /// Segarkan satu produk (misalnya stok terbaru dari halaman detail).
  void applyFresh(Product product) {
    final index = _all.indexWhere((p) => p.id == product.id);
    if (index == -1) {
      _all = [..._all, product];
    } else {
      final next = List<Product>.of(_all);
      next[index] = product;
      _all = next;
    }
    HiveCacheService.instance.setProductDetail(product);
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // INTERNAL
  // -----------------------------------------------------------------------

  void _resetPagination() {
    _currentPage = 1;
    _hasMore = true;
    _all = const [];
    _hasLoaded = false;
    _errorMessage = null;
  }

  Future<void> _loadFromCache() async {
    final hive = HiveCacheService.instance;
    if (!hive.isReady) return;

    final cached = hive.getProductsPage(
      _currentPage,
      _perPage,
      kategori: _category,
      cari: _query.isNotEmpty ? _query : null,
    );

    if (cached != null) {
      final products = cached.products.map((e) => Product.fromJson(e)).toList();
      _all = products;
      _currentPage = cached.currentPage;
      _hasMore = cached.hasMore;
      _hasLoaded = true;
      final catsRaw = await hive.getCategories();
      _apiCategories = catsRaw != null
          ? catsRaw
              .map((e) => category_model.ProductCategory.fromJson(e as Map<String, dynamic>))
              .toList()
          : const [];
      if (_apiCategories.isEmpty) {
        _derivedCategories = _deriveCategories(_all);
      }
      notifyListeners();
    }
  }

  Future<void> _loadFromServer({
    required int page,
    required bool refresh,
  }) async {
    if (refresh) {
      _isInitialLoading = true;
      _errorMessage = null;
      notifyListeners();
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    String? error;
    try {
      final pageResult = await ApiService.getProductsPage(
        page: page,
        perPage: _perPage,
        kategori: _category,
        cari: _query.isNotEmpty ? _query : null,
      );

      final products = pageResult.products;
      if (page == 1) {
        _all = products;
      } else {
        _all = [..._all, ...products];
      }

      _currentPage = pageResult.currentPage;
      _hasMore = pageResult.hasMore;
      _hasLoaded = true;
      _errorMessage = null;

      // Simpan ke cache Hive
      await _saveToCache(pageResult, page);

      // Muat kategori dari server (cache di background)
      try {
        final cats = await ApiService.getCategories();
        _apiCategories = cats;
        await HiveCacheService.instance.setCategories(
          cats.map((c) => {'id': c.id, 'nama': c.nama, 'gambar': c.gambar}).toList(),
        );
      } catch (_) {
        // Kategori gagal, turunkan dari produk
        _derivedCategories = _deriveCategories(_all);
      }
    } on ApiException catch (e) {
      error = e.message;
      if (page == 1 && _all.isEmpty) {
        _errorMessage = e.message;
      } else if (refresh) {
        _refreshError = e.message;
      }
      // Saat offline dan ada cache, jangan tampilkan error yang mengganggu
      if (_isOffline && _all.isNotEmpty) {
        error = null;
      }
    } catch (_) {
      error = 'Produk belum dapat dimuat. Silakan coba lagi.';
      if (page == 1 && _all.isEmpty) {
        _errorMessage = error;
      } else if (refresh) {
        _refreshError = error;
      }
      if (_isOffline && _all.isNotEmpty) {
        error = null;
      }
    } finally {
      if (refresh) {
        _isInitialLoading = false;
      } else {
        _isLoadingMore = false;
      }
      notifyListeners();
    }
  }

  Future<void> _saveToCache(ProductPage result, int page) async {
    final hive = HiveCacheService.instance;
    if (!hive.isReady) return;
    await hive.setProductsPage(ProductPageCache(
      page: page,
      perPage: _perPage,
      kategori: _category,
      cari: _query.isNotEmpty ? _query : null,
      products: result.products.map((p) => p.toJson()).toList(),
      currentPage: result.currentPage,
      lastPage: result.lastPage,
      total: result.total,
      hasMore: result.hasMore,
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  List<category_model.ProductCategory> _deriveCategories(List<Product> products) {
    final seen = <String>{};
    final result = <category_model.ProductCategory>[];
    for (final p in products) {
      final name = p.kategori.trim();
      if (name.isNotEmpty && seen.add(name.toLowerCase())) {
        result.add(category_model.ProductCategory(
          id: null,
          nama: name,
          gambar: null,
        ));
      }
    }
    return result;
  }
}
