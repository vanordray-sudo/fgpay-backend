import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {
  static String _safeValue(String? value, {String fallback = 'N/A'}) {
    if (value == null || value.trim().isEmpty) {
      return fallback;
    }
    return value.trim();
  }

  static String _formatDate(String rawDate) {
    if (rawDate.trim().isEmpty) {
      return 'N/A';
    }

    try {
      final parsed = DateTime.parse(rawDate).toLocal();

      final day = parsed.day.toString().padLeft(2, '0');
      final month = parsed.month.toString().padLeft(2, '0');
      final year = parsed.year.toString();
      final hour = parsed.hour.toString().padLeft(2, '0');
      final minute = parsed.minute.toString().padLeft(2, '0');

      return '$day/$month/$year à $hour:$minute';
    } catch (_) {
      return rawDate;
    }
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 4,
            child: pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            flex: 6,
            child: pw.Text(
              value,
              textAlign: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 11.5,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<Uint8List> generateReceiptPdf({
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required double amount,
    required String reference,
    required String date,
  }) async {
    final pdf = pw.Document();

    final safeSenderName = _safeValue(senderName);
    final safeSenderPhone = _safeValue(senderPhone);
    final safeReceiverName = _safeValue(receiverName);
    final safeReceiverPhone = _safeValue(receiverPhone);
    final safeReference = _safeValue(reference);
    final formattedDate = _formatDate(date);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  borderRadius: pw.BorderRadius.circular(16),
                  gradient: const pw.LinearGradient(
                    colors: [
                      PdfColor.fromInt(0xFF0D6EFD),
                      PdfColor.fromInt(0xFF3FA2FF),
                    ],
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'FGPay',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Digital Transaction Receipt',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 12,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                    pw.Text(
                      'Transfert réussi',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${amount.toStringAsFixed(2)} HTG',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: PdfColors.blue100),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'Référence: ',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(
                        safeReference,
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              pw.Text(
                'Informations du transfert',
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),

              pw.SizedBox(height: 10),
              pw.Divider(),

              _infoRow('Expéditeur', safeSenderName),
              _infoRow('Téléphone expéditeur', safeSenderPhone),
              _infoRow('Destinataire', safeReceiverName),
              _infoRow('Téléphone destinataire', safeReceiverPhone),
              _infoRow('Référence', safeReference),
              _infoRow('Date', formattedDate),
              _infoRow('Statut', 'Complété'),

              pw.Spacer(),
              pw.Divider(),
              pw.SizedBox(height: 8),

              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'FGPay — Digital Payments for Haiti',
                      style: const pw.TextStyle(
                        fontSize: 11,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Receipt generated successfully',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
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

  static Future<void> printReceipt({
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required double amount,
    required String reference,
    required String date,
  }) async {
    final pdfData = await generateReceiptPdf(
      senderName: senderName,
      senderPhone: senderPhone,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      amount: amount,
      reference: reference,
      date: date,
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
    );
  }

  static Future<void> shareReceiptPdf({
    required String senderName,
    required String senderPhone,
    required String receiverName,
    required String receiverPhone,
    required double amount,
    required String reference,
    required String date,
  }) async {
    final pdfData = await generateReceiptPdf(
      senderName: senderName,
      senderPhone: senderPhone,
      receiverName: receiverName,
      receiverPhone: receiverPhone,
      amount: amount,
      reference: reference,
      date: date,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'fgpay_receipt_$reference.pdf',
    );
  }
}