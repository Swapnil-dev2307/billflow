import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../models/invoice_model.dart';
import '../../models/business_model.dart';
import '../../services/pdf_invoice_service.dart';
import '../../services/share_service.dart';
import '../../constants/app_colors.dart';
import '../dashboard/dashboard_screen.dart';
import 'billing_screen.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final InvoiceModel invoice;
  final BusinessModel business;

  const InvoicePreviewScreen({
    super.key,
    required this.invoice,
    required this.business,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${invoice.invoiceNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share via WhatsApp / Email',
            onPressed: () async {
              final pdfBytes = await PdfInvoiceService.generateA4Invoice(
                invoice: invoice,
                business: business,
              );
              await ShareService.shareInvoicePdf(
                pdfBytes: pdfBytes,
                invoiceNumber: invoice.invoiceNumber,
                customerName: invoice.customerName,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => PdfInvoiceService.generateA4Invoice(
                invoice: invoice,
                business: business,
              ),
              allowPrinting: true,
              allowSharing: true,
              initialPageFormat: PdfPageFormat.a4,
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const DashboardScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.dashboard),
                    label: const Text('DASHBOARD'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const BillingScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('NEW BILL'),
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
