import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'package:intl/intl.dart';


class AppointmentsPage extends StatefulWidget {
  final String phone;

  const AppointmentsPage({
    super.key,
    required this.phone,
  });

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  bool isLoading = true;
  List<dynamic> appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
  try {
    final data = await HealthService.getAppointments(widget.phone);

    if (!mounted) return;

    setState(() {
      appointments = data;
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous médicaux'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('Aucun rendez-vous médical'))
              : ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final item = appointments[index] as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(Icons.calendar_month, color: Colors.green),
                        title: Text(item['doctor_name'] ?? 'Médecin'),
                        subtitle: Text(
                          '${item['clinic_name']} - '
'${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['appointment_date']))}'
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}