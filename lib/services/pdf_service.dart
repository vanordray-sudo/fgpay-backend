import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


class PdfService {
  static Future<void> generatePrescriptionPdf({
    required String patientName,
    String? patientPhone,
    String? patientBirthDate,
    required String doctorName,
    required String medication,
    required String dosage,
    required String duration,
    required String notes,
  }) async {
    final verificationCode =
    'FGS-${DateTime.now().millisecondsSinceEpoch}';
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [

                // HEADER
                pw.Center(
                  child: pw.Text(
                    'FG SANTÉ',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),

                pw.SizedBox(height: 8),

                pw.Center(
  child: pw.Column(
    children: [

      pw.Text(
        'ORDONNANCE MÉDICALE',
        style: pw.TextStyle(
          fontSize: 18,
          color: PdfColors.green700,
        ),
      ),

      pw.SizedBox(height: 12),

      pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
      data: 'http://localhost:3000/api/prescriptions/verify/$verificationCode',
        width: 80,
        height: 80,
      ),

      pw.SizedBox(height: 6),

      pw.Text(
        'Code vérification: $verificationCode',
        style: const pw.TextStyle(fontSize: 10),
      ),
    ],
  ),
),

                pw.SizedBox(height: 40),

                // PATIENT
                pw.Text(
                  'Patient : $patientName',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),

pw.SizedBox(height: 6),

pw.Text('Téléphone : ${patientPhone ?? ""}'),

if (patientBirthDate != null && patientBirthDate.isNotEmpty)
  pw.Text('Date de naissance : $patientBirthDate'),

                pw.SizedBox(height: 30),

                // PRESCRIPTION BOX
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(
                      color: PdfColors.green700,
                      width: 2,
                    ),
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [

                      pw.Text(
                        'Médicament',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      pw.Text(
                        medication,
                        style: const pw.TextStyle(fontSize: 20),
                      ),

                      pw.SizedBox(height: 20),

                      pw.Text(
                        'Dosage',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      pw.Text(
                        dosage,
                        style: const pw.TextStyle(fontSize: 18),
                      ),

                      pw.SizedBox(height: 20),

                      pw.Text(
                        'Durée',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      pw.Text(
                        duration,
                        style: const pw.TextStyle(fontSize: 18),
                      ),

                      pw.SizedBox(height: 20),

                      pw.Text(
                        'Notes',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      pw.Text(
                        notes,
                        style: const pw.TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // SIGNATURE
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Médecin',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 40),

                        pw.Text(doctorName),
                      ],
                    ),

                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Signature',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 40),

                        pw.Container(
                          width: 120,
                          height: 1,
                          color: PdfColors.black,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}