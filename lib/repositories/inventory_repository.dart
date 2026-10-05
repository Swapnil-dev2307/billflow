import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class InventoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of products for a business
  Stream<List<ProductModel>> getProductsStream(String businessId) {
    return _firestore
        .collection('products')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Add new product
  Future<void> addProduct(ProductModel product) async {
    final docRef = _firestore.collection('products').doc();
    final newProduct = ProductModel(
      id: docRef.id,
      businessId: product.businessId,
      itemName: product.itemName,
      sku: product.sku,
      category: product.category,
      costPrice: product.costPrice,
      sellingPrice: product.sellingPrice,
      stockQuantity: product.stockQuantity,
      lowStockThreshold: product.lowStockThreshold,
      unit: product.unit,
      gstRate: product.gstRate,
      updatedAt: DateTime.now(),
    );

    await docRef.set(newProduct.toMap());
  }

  /// Update existing product
  Future<void> updateProduct(ProductModel product) async {
    await _firestore.collection('products').doc(product.id).update(product.toMap());
  }

  /// Delete product
  Future<void> deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
  }

  /// Batch update product stock quantities upon invoice checkout
  Future<void> decrementStock(WriteBatch batch, String productId, int quantitySold) async {
    final docRef = _firestore.collection('products').doc(productId);
    batch.update(docRef, {
      'stockQuantity': FieldValue.increment(-quantitySold),
      'updatedAt': Timestamp.now(),
    });
  }
}
