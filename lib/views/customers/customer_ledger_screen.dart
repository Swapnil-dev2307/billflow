import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/customer_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/customer_model.dart';
import '../../constants/app_colors.dart';

class CustomerLedgerScreen extends StatefulWidget {
  const CustomerLedgerScreen({super.key});

  @override
  State<CustomerLedgerScreen> createState() => _CustomerLedgerScreenState();
}

class _CustomerLedgerScreenState extends State<CustomerLedgerScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final _searchController = TextEditingController();

  void _showAddCustomerDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Customer Record'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Full Name *')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number *')),
            const SizedBox(height: 10),
            TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address (Optional)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                final business = Provider.of<BusinessProvider>(context, listen: false).currentBusiness;
                if (business != null) {
                  final customer = CustomerModel(
                    id: '',
                    businessId: business.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    createdAt: DateTime.now(),
                  );
                  await Provider.of<CustomerProvider>(context, listen: false).addCustomer(customer);
                }
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('SAVE CUSTOMER'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Ledger & Balances'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomerDialog(context),
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('ADD CUSTOMER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => customerProvider.setSearchQuery(val),
              decoration: const InputDecoration(
                hintText: 'Search customer by name or phone...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: customerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customerProvider.filteredCustomers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No customer records found', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: customerProvider.filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = customerProvider.filteredCustomers[index];
                          final hasCredit = customer.outstandingBalance > 0;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: hasCredit
                                    ? AppColors.danger.withOpacity(0.15)
                                    : AppColors.success.withOpacity(0.15),
                                child: Text(
                                  customer.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: hasCredit ? AppColors.danger : AppColors.success,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Contact: ${customer.phone}'),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currencyFormatter.format(customer.outstandingBalance),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: hasCredit ? AppColors.danger : AppColors.success,
                                    ),
                                  ),
                                  Text(
                                    hasCredit ? 'Outstanding Due' : 'Settled',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: hasCredit ? AppColors.danger : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
