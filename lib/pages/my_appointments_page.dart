import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../pages/my_appointments_page.dart';

class MyAppointmentsPage extends StatefulWidget {
  const MyAppointmentsPage({super.key});

  @override
  State<MyAppointmentsPage> createState() => _MyAppointmentsPageState();
}

class _MyAppointmentsPageState extends State<MyAppointmentsPage> {
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
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String formatTime(dynamic value) {
    final text = value.toString();
    return text.length >= 5 ? text.substring(0, 5) : text;
  }

Future<void> cancelAppointment(int id) async {
  final result = await HealthService.cancelAppointment(
    appointmentId: id,
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result['message'] ?? 'Rendez-vous annulé'),
    ),
  );

  await loadAppointments();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes rendez-vous'),
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

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(
                          Icons.calendar_month,
                          color: Colors.green,
                        ),
                        title: Text(item['doctor_name'] ?? 'Médecin'),
                        subtitle: Text(
  '${item['clinic_name'] ?? ''}\n'
  '${formatDate(item['appointment_date'])} à '
  '${formatTime(item['appointment_time'])}\n'
  'Statut: ${item['status'] ?? 'confirmed'}\n'
  '${item['status'] == 'accepted' ? '✅ Votre rendez-vous a été accepté par le médecin' : ''}',
),

trailing: item['status'] == 'cancelled'
    ? const Text(
        'Annulé',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
      )
    : item['status'] == 'accepted'
        ? const Text(
            'ACCEPTÉ',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          )
        : item['status'] == 'rejected'
            ? const Text(
                'REFUSÉ',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              )
            : ElevatedButton(
                onPressed: () => cancelAppointment(item['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Annuler'),
              ),

                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}