import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/invoice_model.dart';
import '../models/customer_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  double discount; // line item discount amount

  CartItem({
    required this.product,
    this.quantity = 1,
    this.discount = 0.0,
  });

  double get grossSubtotal => product.sellingPrice * quantity;
  double get netBeforeTax => grossSubtotal - discount;
  double get taxAmount => (netBeforeTax * product.gstRate) / 100;
  double get totalWithTax => netBeforeTax + taxAmount;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  CustomerModel? _selectedCustomer;
  String _customerName = 'Walk-in Customer';
  String _customerPhone = '';
  double _flatDiscount = 0.0;
  String _paymentMethod = 'Cash'; // 'Cash', 'UPI/Online', 'Credit/Pending'
  bool _isInterStateTax = false; // False = CGST + SGST, True = IGST

  Map<String, CartItem> get items => _items;
  List<CartItem> get cartItemList => _items.values.toList();
  CustomerModel? get selectedCustomer => _selectedCustomer;
  String get customerName => _customerName;
  String get customerPhone => _customerPhone;
  double get flatDiscount => _flatDiscount;
  String get paymentMethod => _paymentMethod;
  bool get isInterStateTax => _isInterStateTax;

  int get totalItemCount => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subTotal => _items.values.fold(0.0, (sum, item) => sum + item.netBeforeTax);

  double get totalTaxAmount => _items.values.fold(0.0, (sum, item) => sum + item.taxAmount);

  double get cgstAmount => _isInterStateTax ? 0.0 : totalTaxAmount / 2;
  double get sgstAmount => _isInterStateTax ? 0.0 : totalTaxAmount / 2;
  double get igstAmount => _isInterStateTax ? totalTaxAmount : 0.0;

  double get grandTotal {
    final total = subTotal + totalTaxAmount - _flatDiscount;
    return total < 0 ? 0.0 : total;
  }

  void addToCart(ProductModel product) {
    if (_items.containsKey(product.id)) {
      if (_items[product.id]!.quantity < product.stockQuantity) {
        _items[product.id]!.quantity += 1;
      }
    } else {
      if (product.stockQuantity > 0) {
        _items[product.id] = CartItem(product: product, quantity: 1);
      }
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int delta) {
    if (_items.containsKey(productId)) {
      final current = _items[productId]!;
      final newQty = current.quantity + delta;
      if (newQty <= 0) {
        _items.remove(productId);
      } else if (newQty <= current.product.stockQuantity) {
        current.quantity = newQty;
      }
      notifyListeners();
    }
  }

  void setLineDiscount(String productId, double discount) {
    if (_items.containsKey(productId)) {
      _items[productId]!.discount = discount;
      notifyListeners();
    }
  }

  void setFlatDiscount(double discount) {
    _flatDiscount = discount;
    notifyListeners();
  }

  void selectCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    if (customer != null) {
      _customerName = customer.name;
      _customerPhone = customer.phone;
    }
    notifyListeners();
  }

  void setWalkInCustomer(String name, String phone) {
    _selectedCustomer = null;
    _customerName = name.isEmpty ? 'Walk-in Customer' : name;
    _customerPhone = phone;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void toggleInterStateTax(bool value) {
    _isInterStateTax = value;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _customerName = 'Walk-in Customer';
    _customerPhone = '';
    _flatDiscount = 0.0;
    _paymentMethod = 'Cash';
    _isInterStateTax = false;
    notifyListeners();
  }

  InvoiceModel buildInvoice({
    required String businessId,
    required String invoiceNumber,
  }) {
    final invoiceItems = _items.values.map((item) {
      return InvoiceItemModel(
        productId: item.product.id,
        itemName: item.product.itemName,
        sku: item.product.sku,
        unitPrice: item.product.sellingPrice,
        quantity: item.quantity,
        unit: item.product.unit,
        gstRate: item.product.gstRate,
        discountAmount: item.discount,
        taxAmount: item.taxAmount,
        totalAmount: item.totalWithTax,
      );
    }).toList();

    final isCredit = _paymentMethod == 'Credit/Pending';
    final amountPaid = isCredit ? 0.0 : grandTotal;
    final balanceDue = isCredit ? grandTotal : 0.0;

    return InvoiceModel(
      id: '',
      invoiceNumber: invoiceNumber,
      businessId: businessId,
      customerId: _selectedCustomer?.id ?? '',
      customerName: _customerName,
      customerPhone: _customerPhone,
      items: invoiceItems,
      subTotal: subTotal,
      flatDiscount: _flatDiscount,
      totalTax: totalTaxAmount,
      cgstAmount: cgstAmount,
      sgstAmount: sgstAmount,
      igstAmount: igstAmount,
      grandTotal: grandTotal,
      paymentMethod: _paymentMethod,
      paymentStatus: isCredit ? 'Pending' : 'Paid',
      amountPaid: amountPaid,
      balanceDue: balanceDue,
      createdAt: DateTime.now(),
    );
  }
}
