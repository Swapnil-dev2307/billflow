import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../repositories/inventory_repository.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryRepository _repository = InventoryRepository();

  List<ProductModel> _products = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _showLowStockOnly = false;
  StreamSubscription? _subscription;

  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  bool get showLowStockOnly => _showLowStockOnly;

  List<ProductModel> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = p.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesLowStock = !_showLowStockOnly || p.isLowStock;
      return matchesSearch && matchesCategory && matchesLowStock;
    }).toList();
  }

  List<ProductModel> get lowStockProducts => _products.where((p) => p.isLowStock).toList();

  List<String> get categories {
    final set = <String>{'All'};
    for (var p in _products) {
      set.add(p.category);
    }
    return set.toList();
  }

  void listenToProducts(String businessId) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.getProductsStream(businessId).listen((items) {
      _products = items;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void toggleLowStockFilter(bool value) {
    _showLowStockOnly = value;
    notifyListeners();
  }

  Future<void> addProduct(ProductModel product) async {
    await _repository.addProduct(product);
  }

  Future<void> updateProduct(ProductModel product) async {
    await _repository.updateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await _repository.deleteProduct(productId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
