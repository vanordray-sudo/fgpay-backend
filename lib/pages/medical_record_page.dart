import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../config/api_config.dart';

class MedicalRecordsPage extends StatefulWidget {
  const MedicalRecordsPage({super.key});

  @override
  State<MedicalRecordsPage> createState() => _MedicalRecordsPageState();
}

class _MedicalRecordsPageState extends State<MedicalRecordsPage> {
  List<dynamic> records = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadRecords();
  }


  Future<void> loadRecords() async {
    final data = await HealthService.getMedicalRecords();

    if (!mounted) return;

    setState(() {
      records = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes résultats médicaux'),
        backgroundColor: Colors.green,
      ),
      body: records.isEmpty
          ? const Center(child: Text('Aucun résultat médical'))
          : ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                return ListTile(
                  leading: const Icon(Icons.description, color: Colors.green),
                  title: Text(record['title'] ?? 'Résultat médical'),
                  subtitle: Text(record['notes'] ?? ''),
                );
              },
            ),
    );
  }
}