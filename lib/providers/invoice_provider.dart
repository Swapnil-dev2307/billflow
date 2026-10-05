import 'dart:async';
import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../repositories/invoice_repository.dart';

class InvoiceProvider extends ChangeNotifier {
  final InvoiceRepository _repository = InvoiceRepository();

  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  StreamSubscription? _subscription;

  List<InvoiceModel> get invoices => _invoices;
  bool get isLoading => _isLoading;

  void listenToInvoices(String businessId) {
    _isLoading = true;
    notifyListeners();

    _subscription?.cancel();
    _subscription = _repository.getInvoicesStream(businessId).listen((items) {
      _invoices = items;
      _isLoading = false;
      notifyListeners();
    });
  }

  // Dashboard Aggregations
  double get todayRevenue {
    final now = DateTime.now();
    return _invoices
        .where((inv) =>
            inv.createdAt.year == now.year &&
            inv.createdAt.month == now.month &&
            inv.createdAt.day == now.day)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  int get todayInvoiceCount {
    final now = DateTime.now();
    return _invoices
        .where((inv) =>
            inv.createdAt.year == now.year &&
            inv.createdAt.month == now.month &&
            inv.createdAt.day == now.day)
        .length;
  }

  double get monthlyRevenue {
    final now = DateTime.now();
    return _invoices
        .where((inv) =>
            inv.createdAt.year == now.year && inv.createdAt.month == now.month)
        .fold(0.0, (sum, inv) => sum + inv.grandTotal);
  }

  double get totalTaxCollected {
    return _invoices.fold(0.0, (sum, inv) => sum + inv.totalTax);
  }

  Future<String> createInvoice(InvoiceModel invoice) async {
    return await _repository.createInvoice(invoice);
  }

  Future<String> getNextInvoiceNumber(String businessId, String prefix) async {
    return await _repository.generateNextInvoiceNumber(businessId, prefix);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
