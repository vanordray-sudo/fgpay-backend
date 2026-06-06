import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../services/health_service.dart';
import 'medical_appointments_page.dart';
import '../pages/my_appointments_page.dart';
import 'prescriptions_page.dart';
import 'doctor_appointments_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool isLoading = true;
  List<dynamic> notifications = [];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
  final walletData = await WalletService.getNotifications();
   final healthData = await HealthService.getNotifications();

  print('WALLET NOTIFS: $walletData');
  print('HEALTH NOTIFS: $healthData');


  if (!mounted) return;

  setState(() {
    notifications = [
      ...healthData,
      ...walletData,
    ];
    isLoading = false;
  });
}

  IconData _iconForType(String type) {
  if (type == 'payment_validated') return Icons.check_circle;
  if (type == 'payment_rejected') return Icons.cancel;
  if (type == 'appointment') return Icons.calendar_month;
  if (type == 'prescription') return Icons.medication;
  return Icons.notifications;
}

Color _colorForType(String type) {
  if (type == 'payment_validated') return Colors.green;
  if (type == 'payment_rejected') return Colors.red;
  if (type == 'appointment') return Colors.green;
  if (type == 'prescription') return Colors.green;
  return Colors.blue;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: loadNotifications,
            icon: const Icon(Icons.refresh),
          ),
        ],
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
                    final type = n['type'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                     child: ListTile(
  leading: Icon(
    _iconForType(type),
    color: _colorForType(type),
  ),
  title: Text(
    n['title'] ?? 'Notification',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
  ),
  subtitle: Text(
    n['message'] ?? '',
  ),

  onTap: () {
final title = n['title'] ?? '';

if (title == 'Nouvelle demande de rendez-vous') {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DoctorAppointmentsPage(),
    ),
  );
  return;
}

  if (type == 'prescription') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PrescriptionsPage(),
      ),
    );
  } else if (type == 'appointment') {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyAppointmentsPage(),
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