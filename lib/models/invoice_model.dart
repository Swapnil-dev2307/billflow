import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceItemModel {
  final String productId;
  final String itemName;
  final String sku;
  final double unitPrice;
  final int quantity;
  final String unit;
  final double gstRate; // GST percentage e.g. 18.0
  final double discountAmount;
  final double taxAmount;
  final double totalAmount;

  InvoiceItemModel({
    required this.productId,
    required this.itemName,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.unit,
    required this.gstRate,
    this.discountAmount = 0.0,
    required this.taxAmount,
    required this.totalAmount,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'itemName': itemName,
      'sku': sku,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'unit': unit,
      'gstRate': gstRate,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
    };
  }

  factory InvoiceItemModel.fromMap(Map<String, dynamic> map) {
    return InvoiceItemModel(
      productId: map['productId'] ?? '',
      itemName: map['itemName'] ?? '',
      sku: map['sku'] ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unit: map['unit'] ?? 'Pcs',
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String businessId;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<InvoiceItemModel> items;
  final double subTotal;
  final double flatDiscount;
  final double totalTax;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double grandTotal;
  final String paymentMethod; // 'Cash', 'UPI/Online', 'Credit/Pending'
  final String paymentStatus; // 'Paid', 'Pending', 'Partial'
  final double amountPaid;
  final double balanceDue;
  final DateTime createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.businessId,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.subTotal,
    this.flatDiscount = 0.0,
    required this.totalTax,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.amountPaid,
    required this.balanceDue,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'businessId': businessId,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toMap()).toList(),
      'subTotal': subTotal,
      'flatDiscount': flatDiscount,
      'totalTax': totalTax,
      'cgstAmount': cgstAmount,
      'sgstAmount': sgstAmount,
      'igstAmount': igstAmount,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'amountPaid': amountPaid,
      'balanceDue': balanceDue,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map, String id) {
    return InvoiceModel(
      id: id,
      invoiceNumber: map['invoiceNumber'] ?? '',
      businessId: map['businessId'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Walk-in Customer',
      customerPhone: map['customerPhone'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => InvoiceItemModel.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      subTotal: (map['subTotal'] as num?)?.toDouble() ?? 0.0,
      flatDiscount: (map['flatDiscount'] as num?)?.toDouble() ?? 0.0,
      totalTax: (map['totalTax'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (map['cgstAmount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (map['sgstAmount'] as num?)?.toDouble() ?? 0.0,
      igstAmount: (map['igstAmount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grandTotal'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      paymentStatus: map['paymentStatus'] ?? 'Paid',
      amountPaid: (map['amountPaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (map['balanceDue'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
