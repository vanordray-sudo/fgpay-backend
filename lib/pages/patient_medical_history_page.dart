import 'package:flutter/material.dart';
import '../services/medical_record_service.dart';
import 'medical_record_details_page.dart';
import 'patient_prescriptions_page.dart';
import 'patient_records_page.dart';
import 'add_prescription_page.dart';
import 'medical_results_page.dart';



class PatientMedicalHistoryPage extends StatefulWidget {
  final int patientId;

  const PatientMedicalHistoryPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientMedicalHistoryPage> createState() =>
      _PatientMedicalHistoryPageState();
}

class _PatientMedicalHistoryPageState
    extends State<PatientMedicalHistoryPage> {

  List records = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    try {
     final result =
    await MedicalRecordService
        .getPatientMedicalRecords(
            widget.patientId);


print('PATIENT RECORDS RESULT: $result');
print('PATIENT RECORDS COUNT: ${result.length}');
    

      setState(() {
        records = result;
        loading = false;
        
print('RECORDS: $records');

for (var item in records) {
  print('TYPE: ${item['type']}');
  print('TITLE: ${item['title']}');
}

print('PATIENT ID PRESCRIPTION PAGE: ${widget.patientId}');

      });
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Mon dossier médical"),
        backgroundColor: Colors.green,
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
         : ListView(
    padding: const EdgeInsets.all(16),

    children: [
 


  

  ...records
    .where((item) => item['type'] != 'Prescription')
    .map((item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(
  item['type'] == 'Analyse'
      ? Icons.science
      : item['type'] == 'Référence'
          ? Icons.send
          : Icons.folder,
  color: Colors.green,
),
        title: Text(
          item['title'] ?? 'Sans titre',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item['description'] ?? ''),
            const SizedBox(height: 6),
            Text("Médecin: ${item['doctor_name'] ?? '-'}"),
            Text("Date: ${item['created_at'] ?? '-'}"),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MedicalRecordDetailsPage(
                record: item,
              ),
            ),
          );
        },
      ),
    );
  }).toList(),
],
         
    ),
    );
  }
    }