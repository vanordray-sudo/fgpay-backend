import 'package:flutter/material.dart';
import '../../services/health_service.dart';
import 'medical_record_details_page.dart';

class AdminMedicalRecordsPage extends StatefulWidget {
  const AdminMedicalRecordsPage({super.key});

  @override
  State<AdminMedicalRecordsPage> createState() =>
      _AdminMedicalRecordsPageState();
}

class _AdminMedicalRecordsPageState
    extends State<AdminMedicalRecordsPage> {
  bool isLoading = true;
  List records = [];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final data = await HealthService.getAdminMedicalRecords();

    if (!mounted) return;

    setState(() {
      records = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats médicaux Admin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : records.isEmpty
              ? const Center(child: Text('Aucun résultat médical'))
              : ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(Icons.science, color: Colors.green),
                        title: Text(item['title'] ?? 'Résultat médical'),
                        subtitle: Text(
                          'Patient: ${item['patient_name'] ?? ''}\n'
                          'Catégorie: ${item['category'] ?? item['type'] ?? ''}\n'
                          'Médecin: ${item['doctor_name'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  MedicalRecordDetailsPage(record: item),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}