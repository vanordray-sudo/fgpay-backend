import '../services/health_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/prescription_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/auth_service.dart';


class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() =>
      _PrescriptionsPageState();
}

class _PrescriptionsPageState
    extends State<PrescriptionsPage> {

  bool isLoading = true;

  List<Map<String, dynamic>> prescriptions = [];

  @override
  void initState() {
    super.initState();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    try {
      final token =
          await AuthService.getToken();

      const String baseUrl =
    'https://fgpay-backend-production.up.railway.app';

final response = await http.get(
  Uri.parse('$baseUrl/api/prescriptions/doctor'),
  headers: {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  },
);
      final data =
          jsonDecode(response.body);
        
      
      if (!mounted) return;

      setState(() {
        prescriptions =
            List<Map<String, dynamic>>
                .from(
          data is List
              ? data
              : data['prescriptions'] ?? [],
        );

        isLoading = false;
      });

    } catch (e) {

      debugPrint(
        'PRESCRIPTION ERROR: $e',
      );



      if (!mounted) return;


      setState(() {
        isLoading = false;
      });
    }
  }

Future<void> loadResults() async {
  try {
    final data =
    await PrescriptionService().getMyPrescriptions();

    if (!mounted) return;

    setState(() {
      prescriptions = List<Map<String, dynamic>>.from(data);
      isLoading = false;
    });
  } catch (e) {
    debugPrint('PRESCRIPTIONS ERROR: $e');

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}
Future<void> _printPrescription(Map<String, dynamic> item) async {
  await Printing.layoutPdf(
    onLayout: (format) async {
      final pdf = pw.Document();

      print('PDF ITEM = $item');
print('PDF MEDS = ${item['items']}');
final List meds = (item['items'] != null && item['items'] is List)
    ? item['items']
    : [
        {
          'medication': item['medication'] ?? '',
          'dosage': item['dosage'] ?? '',
          'duration': item['duration'] ?? '',
          'instructions': item['notes'] ?? item['instructions'] ?? '',
        }
      ];
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text(
                    'FG SANTÉ',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Center(
  child: pw.Text(
    'ORDONNANCE MÉDICALE',
    style: pw.TextStyle(
      fontSize: 18,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
),
               pw.SizedBox(height: 20),

pw.Center(
  child: pw.BarcodeWidget(
    barcode: pw.Barcode.qrCode(),
    data: item['verification_code'] ?? '',
    width: 80,
    height: 80,
  ),
),

pw.Center(
  child: pw.Text(
    'Code vérification: ${item['verification_code'] ?? ''}',
    style: const pw.TextStyle(fontSize: 8),
  ),
),

pw.SizedBox(height: 30),

pw.Text(
  'Patient : ${item['patient_name'] ?? item['patientName'] ?? item['patient_id'] ?? ''}',
  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
),

pw.SizedBox(height: 25),

pw.Container(
  width: double.infinity,
  padding: const pw.EdgeInsets.all(16),
  decoration: pw.BoxDecoration(
    border: pw.Border.all(width: 1),
    borderRadius: pw.BorderRadius.circular(10),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Médicaments prescrits',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.Text(item['medication'] ?? ''),

      pw.SizedBox(height: 18),

      pw.Text(
        'Instructions',
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      ),
      pw.SizedBox(height: 8),
      pw.Text(item['notes'] ?? item['instructions'] ?? ''),
    ],
  ),
),
pw.Spacer(),

pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Médecin', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 30),
        pw.Text(item['doctor_name'] ?? ''),
      ],
    ),
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 30),
        pw.Text('________________'),
      ],
    ),
  ],
),
              ],
            ),
    
          ),
        ),
            );

      return pdf.save();
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes prescriptions'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prescriptions.isEmpty
              ? const Center(child: Text('Aucune prescription'))
              : ListView.builder(
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {
                    final item = prescriptions[index] as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
  leading: const Icon(
    Icons.medication,
    color: Colors.green,
  ),
  title: Text(item['medication'] ?? 'Traitement'),
  subtitle: Text(
    '${item['dosage'] ?? ''} ${item['duration'] ?? ''}',
  ),
  trailing: IconButton(
  icon: const Icon(Icons.picture_as_pdf, color: Colors.green),
  onPressed: () {
    _printPrescription(item);
  },
),
),
                    );
                  },
                ),
    );
  }
}