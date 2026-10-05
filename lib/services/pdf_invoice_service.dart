import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/invoice_model.dart';
import '../models/business_model.dart';

class PdfInvoiceService {
  /// Generate A4 PDF Document for Invoice
  static Future<Uint8List> generateA4Invoice({
    required InvoiceModel invoice,
    required BusinessModel business,
  }) async {
    final pdf = pw.Document();
    final currencyFormatter = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final dateFormatter = DateFormat('dd-MM-yyyy hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            cross: pw.CrossAxisAlignment.start,
            children: [
              // Header Section (Shop & Logo)
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                cross: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    cross: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        business.shopName,
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(business.address, style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Phone: ${business.contactNumber}', style: const pw.TextStyle(fontSize: 10)),
                      if (business.gstin.isNotEmpty)
                        pw.Text('GSTIN: ${business.gstin}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    cross: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.blue900,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text('Invoice #: ${invoice.invoiceNumber}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Text('Date: ${dateFormatter.format(invoice.createdAt)}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 10),

              // Customer Details
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  main: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      cross: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Billed To:', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        pw.Text(invoice.customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        if (invoice.customerPhone.isNotEmpty)
                          pw.Text('Contact: ${invoice.customerPhone}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      cross: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Payment Mode: ${invoice.paymentMethod}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Status: ${invoice.paymentStatus}', style: pw.TextStyle(
                          fontSize: 10,
                          color: invoice.paymentStatus == 'Paid' ? PdfColors.green700 : PdfColors.red700,
                          fontWeight: pw.FontWeight.bold,
                        )),
                      ],
                    )
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Table.fromTextArray(
                headers: ['S.No', 'Item Name', 'Qty', 'Unit Price', 'GST %', 'Tax', 'Total'],
                data: List.generate(invoice.items.length, (index) {
                  final item = invoice.items[index];
                  return [
                    '${index + 1}',
                    item.itemName,
                    '${item.quantity} ${item.unit}',
                    currencyFormatter.format(item.unitPrice),
                    '${item.gstRate.toStringAsFixed(0)}%',
                    currencyFormatter.format(item.taxAmount),
                    currencyFormatter.format(item.totalAmount),
                  ];
                }),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellHeight: 24,
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                  6: pw.Alignment.centerRight,
                },
              ),
              pw.SizedBox(height: 16),

              // Totals & Tax Summary
              pw.Row(
                main: pw.MainAxisAlignment.spaceBetween,
                cross: pw.CrossAxisAlignment.start,
                children: [
                  // GST Tax Breakdown Box
                  pw.Container(
                    width: 240,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      cross: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Tax Breakdown Summary', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                        pw.SizedBox(height: 4),
                        if (invoice.cgstAmount > 0)
                          pw.Row(
                            main: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('CGST Total:', style: const pw.TextStyle(fontSize: 8)),
                              pw.Text(currencyFormatter.format(invoice.cgstAmount), style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        if (invoice.sgstAmount > 0)
                          pw.Row(
                            main: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('SGST Total:', style: const pw.TextStyle(fontSize: 8)),
                              pw.Text(currencyFormatter.format(invoice.sgstAmount), style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                        if (invoice.igstAmount > 0)
                          pw.Row(
                            main: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('IGST Total:', style: const pw.TextStyle(fontSize: 8)),
                              pw.Text(currencyFormatter.format(invoice.igstAmount), style: const pw.TextStyle(fontSize: 8)),
                            ],
                          ),
                      ],
                    ),
                  ),

                  // Grand Total Summary Box
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        pw.Row(
                          main: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Sub Total:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(currencyFormatter.format(invoice.subTotal), style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        if (invoice.flatDiscount > 0)
                          pw.Row(
                            main: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                              pw.Text('-${currencyFormatter.format(invoice.flatDiscount)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700)),
                            ],
                          ),
                        pw.Row(
                          main: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Total Tax:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text(currencyFormatter.format(invoice.totalTax), style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          main: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                            pw.Text(currencyFormatter.format(invoice.grandTotal), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),

              pw.Spacer(),

              // Footer Section
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text('Thank you for your business!', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.blue900)),
                    pw.SizedBox(height: 2),
                    pw.Text('Generated securely via BillFlow Smart Billing Application', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Print or Display Preview Direct
  static Future<void> printInvoice(InvoiceModel invoice, BusinessModel business) async {
    final pdfBytes = await generateA4Invoice(invoice: invoice, business: business);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
  }
}
