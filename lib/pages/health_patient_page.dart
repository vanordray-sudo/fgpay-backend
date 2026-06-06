import 'package:flutter/material.dart';
import 'patient_referrals_page.dart';
import 'patient_appointments_page.dart';
import 'patient_prescriptions_page.dart';
import 'patient_records_page.dart';
import 'qr_verify_page.dart';
import 'patient_referrals_page.dart';
import 'package:fgpay_clean/pages/my_appointments_page.dart';
import 'medical_record_page.dart';
import '../config/api_config.dart';
import 'patient_medical_history_page.dart';
import 'add_appointment_page.dart';
import 'patient_signed_prescriptions_page.dart';
import 'secretary_create_appointment_page.dart';
import 'notifications_page.dart';

class HealthPatientPage extends StatelessWidget {
  const HealthPatientPage({super.key});

  Widget _card({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Patient'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [ 
            _card(
              context: context,
              icon: Icons.description,
              title: 'Mes résultats médicaux',
              subtitle: 'Voir mes analyses et résultats',
            page: const PatientRecordsPage(
  patientId: 3,
),
),


_card(
  context: context,
  icon: Icons.qr_code_scanner,
  title: 'Vérifier document',
  subtitle: 'Scanner QR code FG Santé',
  page: const QrVerifyPage(),
),




            
            _card(
              context: context,
              icon: Icons.send,
             title: 'Mes orientations médicales',
             subtitle: 'Voir les spécialistes recommandés',
             page: const PatientReferralsPage(),
            ),

            _card(
  context: context,
  icon: Icons.calendar_month,
  title: 'Mes rendez-vous',
  subtitle: 'Suivre mes rendez-vous médicaux',
  page: const MyAppointmentsPage(),
),
          

_card(
  context: context,
  icon: Icons.notifications,
  title: 'Notifications',
  subtitle: 'Réponses des médecins',
  page: const NotificationsPage(),
),

     _card(
  context: context,
  icon: Icons.add_circle_outline,
  title: 'Prendre rendez-vous',
  subtitle: 'Créer votre propre rendez-vous',
  page: const SecretaryCreateAppointmentPage(),
),       
          

_card(
context: context,
icon: Icons.folder_shared,
title: 'Mon dossier médical',
subtitle: 'Historique médical complet',
page: PatientMedicalHistoryPage(
  patientId: 4,
),
),

          ],
        ),
      ),
    );
  }
}