import 'package:flutter/foundation.dart';
import '../models/banner.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';

/// State management untuk katalog produk.
/// Mendukung 4 keadaan layar: memuat, berhasil, kosong, galat.
class ProductProvider extends ChangeNotifier {
  List<Product> _products = [];
  List<BannerModel> _banners = [];
  List<CategoryModel> _categories = [];
  String? _selectedCategory;
  String? _searchQuery;
  String? _sortBy;

  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;
  bool _hasError = false;

  List<Product> get products => _products;
  List<BannerModel> get banners => _banners;
  List<CategoryModel> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  String? get sortBy => _sortBy;
  bool get isLoading => _isLoading;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _hasError;
  bool get isEmpty => _products.isEmpty;

  Future<void> loadBanners() async {
    try {
      _banners = await ApiService.getBanners();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading banners: $e');
    }
  }

  Future<void> loadCategories() async {
    try {
      _categories = await ApiService.getCategories();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> loadProducts({String? kategori, String? cari, String? sortBy}) async {
    _setState(loading: true, refreshing: false, error: null);
    List<Product>? result;
    try {
      result = await ApiService.getProducts(kategori: kategori, cari: cari);
      _sortBy = sortBy;
      _selectedCategory = kategori;
      _searchQuery = cari;
      _products = _applySort(result, sortBy);
      _errorMessage = null;
      _hasError = false;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
    } finally {
      _setState(loading: false, refreshing: false);
    }
  }

  Future<void> refresh() async {
    _setState(refreshing: true, error: null);
    List<Product>? result;
    try {
      result = await ApiService.getProducts(
        kategori: _selectedCategory,
        cari: _searchQuery,
      );
      _products = _applySort(result, _sortBy);
      _errorMessage = null;
      _hasError = false;
    } on Exception catch (e) {
      _errorMessage = e.toString();
      _hasError = true;
    } finally {
      _setState(refreshing: false);
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
