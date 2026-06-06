import 'package:flutter/material.dart';

class AdminPatientAppointmentsPage extends StatelessWidget {
  const AdminPatientAppointmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rendez-vous patients'),
      ),
      body: const Center(
        child: Text('Liste des rendez-vous admin'),
      ),
    );
  }
}