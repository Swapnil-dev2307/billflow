import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_model.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of customers for a business
  Stream<List<CustomerModel>> getCustomersStream(String businessId) {
    return _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Add new customer
  Future<CustomerModel> addCustomer(CustomerModel customer) async {
    final docRef = _firestore.collection('customers').doc();
    final newCustomer = CustomerModel(
      id: docRef.id,
      businessId: customer.businessId,
      name: customer.name,
      phone: customer.phone,
      email: customer.email,
      outstandingBalance: customer.outstandingBalance,
      createdAt: DateTime.now(),
    );

    await docRef.set(newCustomer.toMap());
    return newCustomer;
  }

  /// Update customer balance when credit/pending invoice is generated
  Future<void> updateCustomerBalance(WriteBatch batch, String customerId, double addedBalance) async {
    final docRef = _firestore.collection('customers').doc(customerId);
    batch.update(docRef, {
      'outstandingBalance': FieldValue.increment(addedBalance),
    });
  }
}
