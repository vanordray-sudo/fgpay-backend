import 'package:flutter/material.dart';
import '../services/health_service.dart';

class DoctorAvailabilityListPage extends StatefulWidget {
  const DoctorAvailabilityListPage({super.key});

  @override
  State<DoctorAvailabilityListPage> createState() =>
      _DoctorAvailabilityListPageState();
}

class _DoctorAvailabilityListPageState
    extends State<DoctorAvailabilityListPage> {
  bool isLoading = true;
  List<dynamic> availabilities = [];

  @override
  void initState() {
    super.initState();
    loadAvailabilities();
  }

  Future<void> loadAvailabilities() async {
    final data = await HealthService.getDoctorAvailabilities();

    if (!mounted) return;

    setState(() {
      availabilities = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendrier médecin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : availabilities.isEmpty
              ? const Center(child: Text('Aucune disponibilité'))
              : ListView.builder(
                  itemCount: availabilities.length,
                  itemBuilder: (context, index) {
                    final item =
                        availabilities[index] as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_month,
                          color: Colors.green,
                        ),
                        title: Text(
                          item['doctor_name'] ?? 'Médecin',
                        ),
                        subtitle: Text(
                          '${item['clinic_name'] ?? ''}\n'
                          '${item['available_date'] ?? ''} | '
                          '${item['start_time'] ?? ''} - '
                          '${item['end_time'] ?? ''}',
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}