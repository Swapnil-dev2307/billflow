import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  /// Export PDF bytes to temporary directory and launch Share Sheet (WhatsApp / Email)
  static Future<void> shareInvoicePdf({
    required Uint8List pdfBytes,
    required String invoiceNumber,
    required String customerName,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Invoice_$invoiceNumber.pdf');
    await file.writeAsBytes(pdfBytes);

    final xFile = XFile(file.path);
    await Share.shareXFiles(
      [xFile],
      text: 'Tax Invoice #$invoiceNumber for $customerName.\nSent via BillFlow App.',
      subject: 'Invoice #$invoiceNumber from BillFlow',
    );
  }
}
