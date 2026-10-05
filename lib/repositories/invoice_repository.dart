import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/invoice_model.dart';
import 'inventory_repository.dart';
import 'customer_repository.dart';

class InvoiceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InventoryRepository _inventoryRepo = InventoryRepository();
  final CustomerRepository _customerRepo = CustomerRepository();

  /// Create Invoice with Atomic Batch (Invoice Doc + Stock Decrement + Customer Ledger Update)
  Future<String> createInvoice(InvoiceModel invoice) async {
    final batch = _firestore.batch();
    final docRef = _firestore.collection('invoices').doc();

    final newInvoice = InvoiceModel(
      id: docRef.id,
      invoiceNumber: invoice.invoiceNumber,
      businessId: invoice.businessId,
      customerId: invoice.customerId,
      customerName: invoice.customerName,
      customerPhone: invoice.customerPhone,
      items: invoice.items,
      subTotal: invoice.subTotal,
      flatDiscount: invoice.flatDiscount,
      totalTax: invoice.totalTax,
      cgstAmount: invoice.cgstAmount,
      sgstAmount: invoice.sgstAmount,
      igstAmount: invoice.igstAmount,
      grandTotal: invoice.grandTotal,
      paymentMethod: invoice.paymentMethod,
      paymentStatus: invoice.paymentStatus,
      amountPaid: invoice.amountPaid,
      balanceDue: invoice.balanceDue,
      createdAt: DateTime.now(),
    );

    // 1. Set Invoice Document
    batch.set(docRef, newInvoice.toMap());

    // 2. Decrement Stock Quantities for each item in cart
    for (var item in invoice.items) {
      await _inventoryRepo.decrementStock(batch, item.productId, item.quantity);
    }

    // 3. Update Customer Outstanding Balance if Credit/Pending
    if (invoice.customerId.isNotEmpty && invoice.balanceDue > 0) {
      await _customerRepo.updateCustomerBalance(batch, invoice.customerId, invoice.balanceDue);
    }

    // Commit atomic batch transaction
    await batch.commit();
    return docRef.id;
  }

  /// Stream of invoices for a business
  Stream<List<InvoiceModel>> getInvoicesStream(String businessId) {
    return _firestore
        .collection('invoices')
        .where('businessId', isEqualTo: businessId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvoiceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Generate Next Invoice Number based on count
  Future<String> generateNextInvoiceNumber(String businessId, String prefix) async {
    final query = await _firestore
        .collection('invoices')
        .where('businessId', isEqualTo: businessId)
        .get();

    final nextNum = query.docs.length + 1;
    final formattedNumber = nextNum.toString().padLeft(4, '0');
    return '$prefix$formattedNumber';
  }
}
