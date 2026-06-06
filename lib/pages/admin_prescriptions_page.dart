import 'package:flutter/material.dart';
import '../../services/health_service.dart';

class AdminPrescriptionsPage extends StatefulWidget {
  const AdminPrescriptionsPage({super.key});

  @override
  State<AdminPrescriptionsPage> createState() =>
      _AdminPrescriptionsPageState();
}

class _AdminPrescriptionsPageState
    extends State<AdminPrescriptionsPage> {

  List prescriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    final data =
        await HealthService.getAdminPrescriptions();

    if (!mounted) return;

    setState(() {
      prescriptions = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions Admin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : prescriptions.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune prescription',
                  ),
                )
              : ListView.builder(
                  itemCount: prescriptions.length,
                  itemBuilder: (context, index) {

                    final item =
                        prescriptions[index];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.medication,
                          color: Colors.green,
                        ),

                        title: Text(
                          item['medication'] ?? '',
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              'Patient: ${item['patient_name'] ?? ''}',
                            ),

                            Text(
                              'Dosage: ${item['dosage'] ?? ''}',
                            ),

                            Text(
                              'Durée: ${item['duration'] ?? ''}',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}