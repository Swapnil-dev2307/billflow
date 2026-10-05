import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/customer_provider.dart';
import '../../models/customer_model.dart';
import '../../constants/app_colors.dart';
import 'invoice_preview_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _searchController = TextEditingController();
  final _walkInNameController = TextEditingController();
  final _walkInPhoneController = TextEditingController();
  final _flatDiscountController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _walkInNameController.dispose();
    _walkInPhoneController.dispose();
    _flatDiscountController.dispose();
    super.dispose();
  }

  void _showCustomerSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final customerProvider = Provider.of<CustomerProvider>(ctx);
        return Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select or Add Customer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                onChanged: (val) => customerProvider.setSearchQuery(val),
                decoration: const InputDecoration(
                  hintText: 'Search customer name or phone...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: customerProvider.filteredCustomers.isEmpty
                    ? const Center(child: Text('No customers found.'))
                    : ListView.builder(
                        itemCount: customerProvider.filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = customerProvider.filteredCustomers[index];
                          return ListTile(
                            leading: const Icon(Icons.person, color: AppColors.accent),
                            title: Text(customer.name),
                            subtitle: Text(customer.phone),
                            trailing: Text(
                              'Bal: ${currencyFormatter.format(customer.outstandingBalance)}',
                              style: TextStyle(
                                color: customer.outstandingBalance > 0 ? AppColors.danger : AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              Provider.of<CartProvider>(context, listen: false).selectCustomer(customer);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
              ),
              const Divider(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddCustomerDialog(context);
                },
                icon: const Icon(Icons.person_add),
                label: const Text('CREATE NEW CUSTOMER'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final business = Provider.of<BusinessProvider>(context, listen: false).currentBusiness;
                if (business != null) {
                  final newCustomer = CustomerModel(
                    id: '',
                    businessId: business.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  final created = await Provider.of<CustomerProvider>(context, listen: false).addCustomer(newCustomer);
                  if (created != null && mounted) {
                    Provider.of<CartProvider>(context, listen: false).selectCustomer(created);
                  }
                }
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('SAVE'),
          )
        ],
      ),
    );
  }

  void _checkout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final business = Provider.of<BusinessProvider>(context, listen: false).currentBusiness;
    final invoiceProvider = Provider.of<InvoiceProvider>(context, listen: false);

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add products to build bill.'), backgroundColor: AppColors.warning),
      );
      return;
    }

    if (business == null) return;

    final invoiceNumber = await invoiceProvider.getNextInvoiceNumber(business.id, business.invoicePrefix);
    final invoice = cart.buildInvoice(businessId: business.id, invoiceNumber: invoiceNumber);

    // Save invoice & commit stock decrement in Firestore
    final invoiceId = await invoiceProvider.createInvoice(invoice);
    final savedInvoice = invoice;

    if (mounted) {
      // Clear cart
      cart.clearCart();
      // Navigate to PDF invoice preview screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => InvoicePreviewScreen(invoice: savedInvoice, business: business),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventoryProvider = Provider.of<InventoryProvider>(context);
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fast POS Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Cart',
            onPressed: cart.items.isEmpty ? null : () => cart.clearCart(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar for Products
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => inventoryProvider.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search products by name or SKU barcode...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          inventoryProvider.setSearchQuery('');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // 2. Product Search Quick Selector (Horizontal Chips)
          if (inventoryProvider.filteredProducts.isNotEmpty && _searchController.text.isNotEmpty)
            Container(
              height: 90,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: inventoryProvider.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = inventoryProvider.filteredProducts[index];
                  return Card(
                    color: product.stockQuantity == 0 ? Colors.grey.shade200 : AppColors.cardBackground,
                    margin: const EdgeInsets.only(right: 8, bottom: 4),
                    child: InkWell(
                      onTap: product.stockQuantity == 0 ? null : () => cart.addToCart(product),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(currencyFormatter.format(product.sellingPrice), style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                            Text('Stock: ${product.stockQuantity} ${product.unit}', style: TextStyle(fontSize: 10, color: product.isLowStock ? AppColors.danger : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 3. Cart Items List
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text('Your billing cart is empty', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        Text('Search and select products above to start billing', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: cart.cartItemList.length,
                    itemBuilder: (context, index) {
                      final item = cart.cartItemList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.product.itemName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(
                                      '${currencyFormatter.format(item.product.sellingPrice)} | GST: ${item.product.gstRate}%',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),

                              // Quantity Controls (- 1 +)
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove, size: 18),
                                      onPressed: () => cart.updateQuantity(item.product.id, -1),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add, size: 18),
                                      onPressed: () => cart.updateQuantity(item.product.id, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Item Total Price
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(item.totalWithTax),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                  ),
                                  Text(
                                    '+ Tax ${currencyFormatter.format(item.taxAmount)}',
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // 4. Billing Summary Panel & Checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Customer Attachment Header
                InkWell(
                  onTap: () => _showCustomerSelectionModal(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person, color: AppColors.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              cart.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                        const Text('Change', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Tax & Payment Settings Row
                Row(
                  children: [
                    // Payment Method Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: cart.paymentMethod,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          labelText: 'Payment Mode',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'UPI/Online', child: Text('UPI / Online')),
                          DropdownMenuItem(value: 'Credit/Pending', child: Text('Credit / Udhar')),
                        ],
                        onChanged: (val) => cart.setPaymentMethod(val!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Inter-State Tax Toggle (CGST+SGST vs IGST)
                    Row(
                      children: [
                        const Text('IGST', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Switch(
                          value: cart.isInterStateTax,
                          onChanged: (val) => cart.toggleInterStateTax(val),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Calculations Line Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal: ${currencyFormatter.format(cart.subTotal)}', style: const TextStyle(fontSize: 12)),
                    Text('GST Tax: ${currencyFormatter.format(cart.totalTaxAmount)}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                    Text(
                      currencyFormatter.format(cart.grandTotal),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty ? null : _checkout,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.success,
                    ),
                    child: const Text('GENERATE & PRINT INVOICE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
