import 'package:flutter/material.dart';

import 'admin_prescriptions_page.dart';
import 'medical_results_page.dart';
import 'patient_references_page.dart';
import 'admin_professional_validation_page.dart';
import 'patient_medical_history_page.dart';
import 'notifications_page.dart';

class AdminMedicalDocumentsPage extends StatelessWidget {
  const AdminMedicalDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents médicaux'),
        backgroundColor: Colors.blue,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.medication, color: Colors.blue),
            title: const Text('Ordonnances'),
            subtitle: const Text('Prescriptions créées par les médecins'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPrescriptionsPage(),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.folder_shared, color: Colors.orange),
            title: const Text('Références'),
            subtitle: const Text('Références et transferts médicaux'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientReferencesPage(),
                ),
              );
            },
          ),

ListTile(
  leading: const Icon(
    Icons.notifications,
    color: Colors.red,
  ),
  title: const Text('Notifications'),
  subtitle: const Text(
    'Demandes de rendez-vous et alertes',
  ),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsPage(),
      ),
    );
  },
),

          ListTile(
            leading: const Icon(Icons.science, color: Colors.purple),
            title: const Text('Résultats médicaux'),
            subtitle: const Text('Analyses et examens médicaux'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                 builder: (_) => const PatientMedicalHistoryPage(
  patientId: 3,
),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.verified_user, color: Colors.green),
            title: const Text('Validation professionnels'),
            subtitle: const Text('Valider ou rejeter les profils santé'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminProfessionalValidationPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}