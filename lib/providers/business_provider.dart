import 'package:flutter/material.dart';
import '../models/business_model.dart';
import '../repositories/business_repository.dart';

class BusinessProvider extends ChangeNotifier {
  final BusinessRepository _businessRepository = BusinessRepository();

  BusinessModel? _currentBusiness;
  bool _isLoading = false;
  String? _errorMessage;

  BusinessModel? get currentBusiness => _currentBusiness;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasBusiness => _currentBusiness != null;

  Future<void> loadBusinessForUser(String ownerId) async {
    _setLoading(true);
    try {
      _currentBusiness = await _businessRepository.getBusinessByOwner(ownerId);
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  Future<bool> registerBusiness({
    required String ownerId,
    required String shopName,
    required String ownerName,
    required String address,
    required String contactNumber,
    required String gstin,
    String? logoUrl,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final business = BusinessModel(
        id: '',
        ownerId: ownerId,
        shopName: shopName,
        ownerName: ownerName,
        address: address,
        contactNumber: contactNumber,
        gstin: gstin,
        logoUrl: logoUrl,
        createdAt: DateTime.now(),
      );

      _currentBusiness = await _businessRepository.createBusiness(business);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
