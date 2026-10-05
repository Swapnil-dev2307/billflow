import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_model.dart';

class BusinessRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Register/Create new business profile
  Future<BusinessModel> createBusiness(BusinessModel business) async {
    final docRef = _firestore.collection('businesses').doc();
    final newBusiness = BusinessModel(
      id: docRef.id,
      ownerId: business.ownerId,
      shopName: business.shopName,
      ownerName: business.ownerName,
      address: business.address,
      contactNumber: business.contactNumber,
      gstin: business.gstin,
      logoUrl: business.logoUrl,
      invoicePrefix: business.invoicePrefix,
      isGstEnabled: business.isGstEnabled,
      createdAt: DateTime.now(),
    );

    await docRef.set(newBusiness.toMap());
    return newBusiness;
  }

  /// Get business profile by ID
  Future<BusinessModel?> getBusinessById(String businessId) async {
    final doc = await _firestore.collection('businesses').doc(businessId).get();
    if (doc.exists && doc.data() != null) {
      return BusinessModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }

  /// Get business owned by user UID
  Future<BusinessModel?> getBusinessByOwner(String ownerId) async {
    final query = await _firestore
        .collection('businesses')
        .where('ownerId', isEqualTo: ownerId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return BusinessModel.fromMap(query.docs.first.data(), query.docs.first.id);
    }
    return null;
  }

  /// Update business details
  Future<void> updateBusiness(BusinessModel business) async {
    await _firestore
        .collection('businesses')
        .doc(business.id)
        .update(business.toMap());
  }
}
