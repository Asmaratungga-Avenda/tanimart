import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// State management untuk katalog produk.
/// Mendukung 4 keadaan layar: memuat, berhasil, kosong, galat.
class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<String> _categories = [];
  bool _isLoadingCategories = false;
  String? _categoriesError;
  Future<void>? _categoriesRequest;
  String? _selectedCategory;
  String? _searchQuery;
  String? _sortBy;

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasError = false;
  int _productsRequestId = 0;

  List<Product> get products => _products;
  List<String> get categories => List.unmodifiable(_categories);
  bool get isLoadingCategories => _isLoadingCategories;
  String? get categoriesError => _categoriesError;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  String? get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  bool get isEmpty => _products.isEmpty;

  /// Mengambil kategori dari Laravel dan menyimpannya selama provider hidup.
  /// Panggilan paralel tidak membuat request kategori duplikat.
  Future<void> loadCategories({bool forceRefresh = false}) async {
    if (_categoriesRequest != null) return _categoriesRequest!;
    if (!forceRefresh && _categories.isNotEmpty) return;
    final request = _fetchCategories();
    _categoriesRequest = request;
    try {
      await request;
    } finally {
      if (identical(_categoriesRequest, request)) _categoriesRequest = null;
    }
  }

  Future<void> _fetchCategories() async {
    _isLoadingCategories = true;
    _categoriesError = null;
    notifyListeners();
    try {
      final result = await ApiService.getCategories();
      _categories = result
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    } on Exception catch (error) {
      _categoriesError = error.toString();
    } finally {
      _isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts({String? kategori, String? cari, String? sortBy}) async {
    final requestId = ++_productsRequestId;
    _errorMessage = null;
    _hasError = false;
    _setState(loading: true, refreshing: false);
    try {
      final result = await ApiService.getProducts(kategori: kategori, cari: cari);
      if (requestId != _productsRequestId) return;
      _sortBy = sortBy;
      _selectedCategory = kategori;
      _searchQuery = cari;
      _products = _applySort(result, sortBy);
      _errorMessage = null;
      _hasError = false;
    } on Exception catch (error) {
      if (requestId != _productsRequestId) return;
      _errorMessage = error.toString();
      _hasError = true;
    } finally {
      if (requestId == _productsRequestId) {
        _setState(loading: false, refreshing: false);
      }
    }
  }

  Future<void> refresh() async {
    final requestId = ++_productsRequestId;
    _errorMessage = null;
    _hasError = false;
    _setState(loading: false, refreshing: true);
    try {
      final result = await ApiService.getProducts(
        kategori: _selectedCategory,
        cari: _searchQuery,
      );
      if (requestId != _productsRequestId) return;
      _products = _applySort(result, _sortBy);
      _errorMessage = null;
      _hasError = false;
    } on Exception catch (error) {
      if (requestId != _productsRequestId) return;
      _errorMessage = error.toString();
      _hasError = true;
    } finally {
      if (requestId == _productsRequestId) {
        _setState(loading: false, refreshing: false);
      }
    }
  }

  void setCategory(String? kategori) {
    _selectedCategory = kategori;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<Product> _applySort(List<Product> list, String? sortBy) {
    final sorted = List<Product>.from(list);
    switch (sortBy) {
      case 'price_asc':
        sorted.sort((a, b) => a.harga.compareTo(b.harga));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.harga.compareTo(a.harga));
        break;
      case 'name':
        sorted.sort((a, b) => a.nama.compareTo(b.nama));
        break;
      default:
        break;
    }
    return sorted;
  }

  void _setState({
    bool? loading,
    bool? refreshing,
    String? error,
  }) {
    if (loading != null) _isLoading = loading;
    if (refreshing != null) _isRefreshing = refreshing;
    if (error != null) _errorMessage = error;
    notifyListeners();
  }
}
