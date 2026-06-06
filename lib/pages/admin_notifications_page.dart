import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'doctor_appointments_page.dart';
import 'admin_patient_appointments_page.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  bool isLoading = true;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final result = await HealthService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      print('ADMIN NOTIFICATIONS ERROR: $e');

      if (!mounted) return;

      setState(() {
        notifications = [];
        isLoading = false;
      });
    }
  }

  IconData iconForType(String type) {
    if (type == 'appointment') return Icons.calendar_month;
    if (type == 'prescription') return Icons.description;
    if (type == 'result') return Icons.science;
    return Icons.notifications;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications Admin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? const Center(child: Text('Aucune notification'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    final type = n['type']?.toString() ?? '';
                    final title = n['title']?.toString() ?? 'Notification';
                    final message = n['message']?.toString() ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          iconForType(type),
                          color: Colors.green,
                        ),
                        title: Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(message),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          if (type == 'appointment') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AdminPatientAppointmentsPage(),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
    );
  }
}