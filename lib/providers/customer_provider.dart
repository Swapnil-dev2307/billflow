import 'dart:async';
import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String _searchQuery = '';
  StreamSubscription? _subscription;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;

  List<CustomerModel> get filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.phone.contains(_searchQuery))
        .toList();
  }

  void listenToCustomers(String businessId) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.getCustomersStream(businessId).listen((items) {
      _customers = items;
      _isLoading = false;
      notifyListeners();
    });
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<CustomerModel?> addCustomer(CustomerModel customer) async {
    try {
      final newCustomer = await _repository.addCustomer(customer);
      return newCustomer;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
