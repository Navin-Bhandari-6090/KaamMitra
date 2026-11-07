import 'dart:typed_data';
import 'package:app/web/common%20widget/toast.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../common method/date_time.dart';

/// Builds a PDF with the account recovery details and downloads it.
/// Returns 1 on success, 0 on failure. Never throws (full try/catch).
Future<int> downloadCredentialsPdf({
  required String email,
  required String phone,
  required String whatsapp,
  required String password
}) async {
  try {
    final doc = pw.Document();
    final created = formatDateTime(DateTime.now().toIso8601String());

    pw.Widget row(String label, String value) {
      return pw.Container(
        width: double.infinity,
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#EEF7F1'),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor.fromHex('#234232')),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#5E7A6C'),
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value.isEmpty ? 'No data available' : value,
              style: const pw.TextStyle(fontSize: 15),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(18),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F1F17'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'KaamMitra',
                    style: pw.TextStyle(
                      fontSize: 24,
                      color: PdfColor.fromHex('#34D399'),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Account Recovery Details',
                    style: pw.TextStyle(
                      fontSize: 13,
                      color: PdfColor.fromHex('#E6F4EA'),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 22),
            row('EMAIL', email),
            row('PHONE NUMBER', phone),
            row('WHATSAPP NUMBER', whatsapp),
            row('PASSWORD', password),
            pw.SizedBox(height: 8),
            pw.Text(
              'Keep this file safe. You will need these details if you forget your password.Do not delete it.',
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Created: $created',
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColor.fromHex('#5E7A6C'),
              ),
            ),
          ],
        ),
      ),
    );

    final Uint8List bytes = await doc.save();

    await FileSaver.instance.saveFile(
      name: 'KaamMitra_Account_Details',
      bytes: bytes,
      fileExtension: 'pdf', // use `ext: 'pdf'` on file_saver < 0.3.0
      mimeType: MimeType.pdf,
    );

    Toastget().Toastmsg(
        "Your forget password required credentials downloaded successfully.");
    return 1;
  } catch (e) {
    print("Exception in downloadCredentialsPdf: $e");
    Toastget().Toastmsg("Could not download credentials file. Try again.");
    return 0;
  }
}