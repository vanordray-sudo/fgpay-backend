import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import 'doctor_prescription_page.dart';
import 'create_patient_referral_page.dart';
import 'add_medical_record_page.dart';
import 'patient_appointments_page.dart';
import 'doctor_appointments_page.dart';
import 'patient_medical_complete_page.dart';
import 'package:url_launcher/url_launcher.dart';


class ConsultationPage extends StatelessWidget {
  final Map appointment;

  const ConsultationPage({
    super.key,
    required this.appointment,
  });

Future<void> openWhatsApp(String phone) async {
  final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

  final url = Uri.parse(
    'https://wa.me/$cleanPhone?text=Bonjour, ici votre médecin FG Santé.',
  );

  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    throw Exception('Impossible d’ouvrir WhatsApp');
  }
}
String formatDate(dynamic value) {
  if (value == null) return 'Non renseignée';

  final date = DateTime.parse(value.toString()).toLocal();

  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation'),
        backgroundColor: Colors.green,
      ),
    body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        appointment['patient_name'] ?? 'Patient',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      const SizedBox(height: 10),

      Text('Date : ${appointment['appointment_date'] ?? ''}'),
      Text('Heure : ${appointment['appointment_time'] ?? ''}'),
     Text(
  'Téléphone : ${appointment['patient_phone'] ?? ''}',
),
if (appointment['patient_birth_date'] != null)
  Text('Date de naissance : ${appointment['patient_birth_date']}')
else
  ElevatedButton.icon(
    onPressed: () async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime(2000),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (picked == null) return;

      print('BIRTH DATE SELECTED = $picked');

      // apre sa nap voye backend
    },
    icon: const Icon(Icons.cake),
    label: const Text('Ajouter date de naissance'),
  ),



      const SizedBox(height: 20),

      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
         ElevatedButton.icon(
  onPressed: () async {

    final ordonnanceCreated =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorPrescriptionPage(
          appointment: appointment,
        ),
      ),
    );

    if (ordonnanceCreated == true) {

      await AppointmentService.completeAppointment(
        appointment['id'],
      );

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ordonnance créée. Consultation terminée.',
            ),
          ),
        );

        Navigator.pop(context);
      }
    }
  },

  icon: const Icon(Icons.description),
  label: const Text('Créer ordonnance'),
),
          ElevatedButton.icon(
          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const CreatePatientReferralPage(),
    ),
  );
},
            icon: const Icon(Icons.send),
            label: const Text('Créer référence'),
          ),
          ElevatedButton.icon(
          onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddMedicalRecordPage(
        patientId: appointment['patient_id'],
        defaultCategory: 'Analyse',
        pageTitle: 'Ajouter résultat médical',
      ),
    ),
  );
},
            icon: const Icon(Icons.science),
            label: const Text('Résultats labo'),
          ),

ElevatedButton.icon(
  onPressed: () {
    openWhatsApp(appointment['patient_phone'] ?? '');
  },
  icon: const Icon(Icons.chat),
  label: const Text('Contacter patient'),
),

         ElevatedButton.icon(
  onPressed: () {
    print('PATIENT ID = ${appointment['patient_id']}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientMedicalCompletePage(
          patientId: appointment['patient_id'],
        ),
      ),
    );
  },
  icon: const Icon(Icons.folder_shared),
  label: const Text('Dossier Médical'),
),
        ],
      ),

      const SizedBox(height: 20),


      const TextField(
        maxLines: 5,
        decoration: InputDecoration(
          labelText: 'Notes médicales',
          border: OutlineInputBorder(),
        ),
      ),

      const SizedBox(height: 20),

      ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.save),
        label: const Text('Enregistrer consultation'),
      ),

      const SizedBox(height: 12),

      ElevatedButton.icon(
        onPressed: () async {

  final appointmentId =
    appointment['appointment_id'] ?? appointment['id'];

final success =
    await AppointmentService.completeAppointment(appointmentId);

  if (success) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consultation terminée'),
      ),
    );

    Navigator.pop(context);
  }
},
        icon: const Icon(Icons.check_circle),
        label: const Text('Terminer consultation'),
      ),
    ],
  ),
),
    );
  }
}