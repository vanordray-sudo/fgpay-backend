import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'medical_record_detail_page.dart';

class PatientRecordsPage extends StatefulWidget {
  final int patientId;

const PatientRecordsPage({
  super.key,
  required this.patientId,
});

  @override
  State<PatientRecordsPage> createState() => _PatientRecordsPageState();
}

class _PatientRecordsPageState extends State<PatientRecordsPage> {
  List records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    try {
      final result =
    await HealthService.getPatientRecords(
  widget.patientId,
);

      if (!mounted) return;

      setState(() {
        records = result;
        isLoading = false;
      });
    } catch (e) {
      print(e);

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void openDetail(dynamic record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalRecordDetailPage(
          record: Map<String, dynamic>.from(record),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        title: const Text('Mes résultats médicaux'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? const Center(child: Text('Aucun résultat médical'))
              : ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];

                   return Card(
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
 child: InkWell(
  onTap: () {
    print('CLICK RESULTAT OK');
    openDetail(record);
  },
  child: Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    child: Row(
      children: [
        const Icon(Icons.description, color: Colors.green),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            record['title'] ?? 'Résultat médical',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 16),
      ],
    ),
  ),
),
                    );
                  },
                ),
    );
  }
}