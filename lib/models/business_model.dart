import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessModel {
  final String id;
  final String ownerId;
  final String shopName;
  final String ownerName;
  final String address;
  final String contactNumber;
  final String gstin;
  final String? logoUrl;
  final String invoicePrefix;
  final bool isGstEnabled;
  final DateTime createdAt;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.shopName,
    required this.ownerName,
    required this.address,
    required this.contactNumber,
    required this.gstin,
    this.logoUrl,
    this.invoicePrefix = 'INV-',
    this.isGstEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'shopName': shopName,
      'ownerName': ownerName,
      'address': address,
      'contactNumber': contactNumber,
      'gstin': gstin,
      'logoUrl': logoUrl,
      'invoicePrefix': invoicePrefix,
      'isGstEnabled': isGstEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory BusinessModel.fromMap(Map<String, dynamic> map, String id) {
    return BusinessModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      shopName: map['shopName'] ?? '',
      ownerName: map['ownerName'] ?? '',
      address: map['address'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
      gstin: map['gstin'] ?? '',
      logoUrl: map['logoUrl'],
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      isGstEnabled: map['isGstEnabled'] ?? true,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
