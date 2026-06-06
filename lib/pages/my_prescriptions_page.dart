import 'package:flutter/material.dart';
import '../services/health_service.dart';

class MyPrescriptionsPage extends StatefulWidget {
  const MyPrescriptionsPage({super.key});

  @override
  State<MyPrescriptionsPage> createState() => _MyPrescriptionsPageState();
}

class _MyPrescriptionsPageState extends State<MyPrescriptionsPage> {
  bool isLoading = true;
  List<dynamic> prescriptions = [];

  @override
  void initState() {
    super.initState();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    final data = await HealthService.getMyPrescriptions();

    if (!mounted) return;

    setState(() {
      prescriptions = data;
      isLoading = false;
    });
  }

String cleanMedication(dynamic value) {
  final text = (value ?? '').toString();
  final parts = text.split('\n');

  if (parts.length >= 2 && parts[0].trim() == parts[1].trim()) {
    return parts[0].trim();
  }

  return text.trim();
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
                    final item = prescriptions[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(Icons.medication, color: Colors.green),
                        title: Text(
  item['medication'] ?? 'Prescription',
  style: const TextStyle(
    fontWeight: FontWeight.bold,
  ),
),
                       subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
 children: [
  if ((item['dosage'] ?? '').toString().isNotEmpty)
    Text(
      'Dosage: ${item['dosage']}',
      style: const TextStyle(
        fontWeight: FontWeight.w400,
      ),
    ),

  const SizedBox(height: 4),

  Text(
    'Durée: ${item['duration'] ?? ''}',
  ),

  if ((item['notes'] ?? '').toString().isNotEmpty)
    Text(
      'Notes: ${item['notes']}',
    ),
],
),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}