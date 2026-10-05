import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerModel {
  final String id;
  final String businessId;
  final String name;
  final String phone;
  final String email;
  final double outstandingBalance;
  final DateTime createdAt;

  CustomerModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.phone,
    this.email = '',
    this.outstandingBalance = 0.0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'outstandingBalance': outstandingBalance,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomerModel(
      id: id,
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      outstandingBalance: (map['outstandingBalance'] as num?)?.toDouble() ?? 0.0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
