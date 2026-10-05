import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String businessId;
  final String itemName;
  final String sku;
  final String category;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final String unit; // e.g., Pcs, Kg, Ltr, Box
  final double gstRate; // e.g., 0, 5, 12, 18, 28
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.businessId,
    required this.itemName,
    required this.sku,
    required this.category,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    this.lowStockThreshold = 5,
    required this.unit,
    required this.gstRate,
    required this.updatedAt,
  });

  bool get isLowStock => stockQuantity <= lowStockThreshold;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'itemName': itemName,
      'sku': sku,
      'category': category,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'stockQuantity': stockQuantity,
      'lowStockThreshold': lowStockThreshold,
      'unit': unit,
      'gstRate': gstRate,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      businessId: map['businessId'] ?? '',
      itemName: map['itemName'] ?? '',
      sku: map['sku'] ?? '',
      category: map['category'] ?? 'General',
      costPrice: (map['costPrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (map['stockQuantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toInt() ?? 5,
      unit: map['unit'] ?? 'Pcs',
      gstRate: (map['gstRate'] as num?)?.toDouble() ?? 18.0,
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
