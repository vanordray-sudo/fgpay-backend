import 'package:flutter/material.dart';
import '../services/health_service.dart';

class MedicalAppointmentsPage extends StatefulWidget {
  const MedicalAppointmentsPage({super.key});

  @override
  State<MedicalAppointmentsPage> createState() =>
      _MedicalAppointmentsPageState();
}

class _MedicalAppointmentsPageState extends State<MedicalAppointmentsPage> {
  bool isLoading = true;
  List<dynamic> appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
    final data = await HealthService.getMyAppointments();

    if (!mounted) return;

    setState(() {
      appointments = data;
      isLoading = false;
    });
  }

  String formatDate(dynamic value) {
    final date = DateTime.parse(value.toString()).toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String formatTime(dynamic value) {
    final text = value.toString();
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

 Color statusColor(String status) {
  if (status == 'cancelled') return Colors.red;
  if (status == 'accepted') return Colors.green;
  if (status == 'confirmed') return Colors.green;
  return Colors.orange;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous médecin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('Aucun rendez-vous'))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final item =
                        appointments[index] as Map<String, dynamic>;

                    final status = item['status'] ?? 'pending';

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.medical_services,
                          color: Colors.green,
                        ),
                        title: Text(item['patient_name'] ?? 'Patient'),
                        subtitle: Text(
                          '${item['clinic_name'] ?? ''}\n'
                          '${formatDate(item['appointment_date'])} à '
                          '${formatTime(item['appointment_time'])}',
                        ),
                        trailing: Text(
                          status,
                          style: TextStyle(
                            color: statusColor(status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}