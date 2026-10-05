import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/business_provider.dart';
import '../../models/invoice_model.dart';
import '../../constants/app_colors.dart';
import '../billing/invoice_preview_screen.dart';

class InvoiceHistoryScreen extends StatefulWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  State<InvoiceHistoryScreen> createState() => _InvoiceHistoryScreenState();
}

class _InvoiceHistoryScreenState extends State<InvoiceHistoryScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final invoiceProvider = Provider.of<InvoiceProvider>(context);
    final business = Provider.of<BusinessProvider>(context).currentBusiness;

    final filteredInvoices = invoiceProvider.invoices.where((inv) {
      final matchesNumber = inv.invoiceNumber.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCustomer = inv.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesNumber || matchesCustomer;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History & Audit'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search by Invoice # or Customer name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: invoiceProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredInvoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.history_toggle_off, size: 64, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Text('No invoices matching search', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: filteredInvoices.length,
                        itemBuilder: (context, index) {
                          final invoice = filteredInvoices[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.description, color: AppColors.accent),
                              ),
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(
                                    currencyFormatter.format(invoice.grandTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('Customer: ${invoice.customerName}'),
                                  Text(
                                    '${dateFormatter.format(invoice.createdAt)} • Mode: ${invoice.paymentMethod}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                if (business != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => InvoicePreviewScreen(invoice: invoice, business: business),
                                    ),
                                  );
                                }
                              },
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
