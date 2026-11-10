import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../models/product.dart';

/// Layanan cache lokal berbasis Hive.
///
/// Digunakan untuk:
/// - Cache kategori (tidak berubah sering)
/// - Cache halaman produk (strategi cache-first / stale-while-revalidate)
/// - Data sederhana yang perlu tersedia offline
class HiveCacheService {
  HiveCacheService._();
  static final HiveCacheService instance = HiveCacheService._();

  static const String _boxCategories = 'cache_categories';
  static const String _boxProductsPage = 'cache_products_page';
  static const String _boxProductDetail = 'cache_product_detail';
  static const String _boxSimple = 'cache_simple';

  Box<String>? _categories;
  Box<String>? _productsPage;
  Box<String>? _productDetail;
  Box<String>? _simple;

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _categories = await Hive.openBox<String>(_boxCategories);
    _productsPage = await Hive.openBox<String>(_boxProductsPage);
    _productDetail = await Hive.openBox<String>(_boxProductDetail);
    _simple = await Hive.openBox<String>(_boxSimple);
    _initialized = true;
  }

  bool get isReady => _initialized;

  // -----------------------------------------------------------------------
  // KATEGORI
  // -----------------------------------------------------------------------

  Future<List<dynamic>?> getCategories() async {
    if (_categories == null) return null;
    final raw = _categories!.get('list');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> setCategories(List<dynamic> categories) async {
    if (_categories == null) return;
    await _categories!.put('list', jsonEncode(categories));
  }

  // -----------------------------------------------------------------------
  // PRODUK HALAMAN (pagination cache)
  // -----------------------------------------------------------------------

  String _pageKey(int page, int perPage, String? kategori, String? cari) =>
      'p${page}_${perPage}_${kategori ?? 'all'}_${cari ?? ''}';

  ProductPageCache? getProductsPage(int page, int perPage,
      {String? kategori, String? cari}) {
    if (_productsPage == null) return null;
    final raw = _productsPage!.get(_pageKey(page, perPage, kategori, cari));
    if (raw == null) return null;
    try {
      return ProductPageCache.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> setProductsPage(ProductPageCache page) async {
    if (_productsPage == null) return;
    await _productsPage!
        .put(_pageKey(page.page, page.perPage, page.kategori, page.cari),
            jsonEncode(page.toJson()));
  }

  // -----------------------------------------------------------------------
  // PRODUK DETAIL
  // -----------------------------------------------------------------------

  Product? getProductDetail(int id) {
    if (_productDetail == null) return null;
    final raw = _productDetail!.get('prod_$id');
    if (raw == null) return null;
    try {
      return ProductDetailCache.fromJson(
              jsonDecode(raw) as Map<String, dynamic>)
          .toProduct();
    } catch (_) {
      return null;
    }
  }

  Future<void> setProductDetail(Product product) async {
    if (_productDetail == null) return;
    await _productDetail!.put(
        'prod_${product.id}',
        jsonEncode(ProductDetailCache.fromProduct(product).toJson()));
  }

  // -----------------------------------------------------------------------
  // SIMPLE KEY-VALUE
  // -----------------------------------------------------------------------

  String? getString(String key) => _simple?.get(key);

  Future<void> setString(String key, String value) async {
    if (_simple == null) return;
    await _simple!.put(key, value);
  }

  Future<void> clear() async {
    await _categories?.clear();
    await _productsPage?.clear();
    await _productDetail?.clear();
    await _simple?.clear();
  }
}

/// Representasi cache halaman produk.
class ProductPageCache {
  final int page;
  final int perPage;
  final String? kategori;
  final String? cari;
  final List<Map<String, dynamic>> products;
  final int currentPage;
  final int lastPage;
  final int total;
  final bool hasMore;
  final int cachedAt;

  ProductPageCache({
    required this.page,
    required this.perPage,
    this.kategori,
    this.cari,
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
    required this.cachedAt,
  });

  Map<String, dynamic> toJson() => {
        'page': page,
        'per_page': perPage,
        'kategori': kategori,
        'cari': cari,
        'products': products,
        'current_page': currentPage,
        'last_page': lastPage,
        'total': total,
        'has_more': hasMore ? 1 : 0,
        'cached_at': cachedAt,
      };

  factory ProductPageCache.fromJson(Map<String, dynamic> json) {
    return ProductPageCache(
      page: int.tryParse('${json['page']}') ?? 1,
      perPage: int.tryParse('${json['per_page']}') ?? 15,
      kategori: json['kategori']?.toString(),
      cari: json['cari']?.toString(),
      products: (json['products'] as List? ?? []).cast<Map<String, dynamic>>(),
      currentPage: int.tryParse('${json['current_page']}') ?? 1,
      lastPage: int.tryParse('${json['last_page']}') ?? 1,
      total: int.tryParse('${json['total']}') ?? 0,
      hasMore: (json['has_more'] ?? 0) == 1,
      cachedAt: int.tryParse('${json['cached_at']}') ?? 0,
    );
  }
}

/// Representasi cache detail produk.
class ProductDetailCache {
  final Map<String, dynamic> product;
  final int cachedAt;

  ProductDetailCache({required this.product, required this.cachedAt});

  Map<String, dynamic> toJson() => {
        'product': product,
        'cached_at': cachedAt,
      };

  factory ProductDetailCache.fromJson(Map<String, dynamic> json) {
    return ProductDetailCache(
      product: Map<String, dynamic>.from(json['product'] ?? {}),
      cachedAt: int.tryParse('${json['cached_at']}') ?? 0,
    );
  }

  factory ProductDetailCache.fromProduct(Product product) {
    return ProductDetailCache(
      product: product.toJson(),
      cachedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Product toProduct() => Product.fromJson(product);
}
