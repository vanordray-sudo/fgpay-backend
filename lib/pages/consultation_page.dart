import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import 'doctor_prescription_page.dart';
import 'create_patient_referral_page.dart';
import 'add_medical_record_page.dart';
import 'patient_appointments_page.dart';
import 'doctor_appointments_page.dart';


class ConsultationPage extends StatelessWidget {
  final Map appointment;

  const ConsultationPage({
    super.key,
    required this.appointment,
  });

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
  'Téléphone : ${appointment['patient_phone'] ?? 'Non renseigné'}',
),

Text(
  'Date de naissance : ${appointment['patient_birth_date'] ?? 'Non renseignée'}',
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
 print('PATIENT ID = ${appointment['patient_id']}');
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DoctorAppointmentsPage(
  patientId: appointment['patient_id'],
),
      
    ),
  );
},
            icon: const Icon(Icons.history),
            label: const Text('Historique RDV'),
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