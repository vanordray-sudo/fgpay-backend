import 'package:flutter/material.dart';
import '../data/prescriptions_data.dart';
import '../services/health_service.dart';
import '../services/prescription_service.dart';
import 'prescriptions_page.dart';
import 'doctor_prescription_page.dart';
import '../services/appointment_service.dart';

class DoctorPrescriptionPage extends StatefulWidget {
  final Map appointment;

  const DoctorPrescriptionPage({
    super.key,
    required this.appointment,
  });

  @override
  State<DoctorPrescriptionPage> createState() =>
      _DoctorPrescriptionPageState();
}
class PrescriptionItem {
  final TextEditingController medicationController;
  final TextEditingController dosageController;
  final TextEditingController durationController;
  final TextEditingController instructionController;

  PrescriptionItem()
      : medicationController = TextEditingController(),
        dosageController = TextEditingController(),
        durationController = TextEditingController(),
        instructionController = TextEditingController();
}


class _DoctorPrescriptionPageState
    extends State<DoctorPrescriptionPage> {
  final medicationController = TextEditingController();
  final dosageController = TextEditingController();
  final durationController = TextEditingController();
  final notesController = TextEditingController();
  final patientIdController = TextEditingController();
  final patientNameController = TextEditingController();
  final doctorNameController = TextEditingController();
  final clinicNameController = TextEditingController();
  final prescriptionDateController = TextEditingController();

final List<PrescriptionItem> medications = [ PrescriptionItem(),];


  int? patientId;
  int? appointmentId;

  bool isLoading = false;

@override
void initState() {
  super.initState();

  patientNameController.text =
      widget.appointment['patient_name']?.toString() ?? '';

  patientId = widget.appointment['patient_id'] ??
      widget.appointment['user_id'] ??
      widget.appointment['patientId'];

  appointmentId = widget.appointment['appointment_id'] ??
      widget.appointment['id'];

      doctorNameController.text = 'Dr James Constant';
clinicNameController.text = 'FG Centre de Santé';
prescriptionDateController.text =
    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
}

Future<void> savePrescription() async {
  try {
    setState(() => isLoading = true);

    print("APPOINTMENT DATA: ${widget.appointment}");

    final finalPatientId = patientId;
    final finalAppointmentId = appointmentId;
   
   print("PATIENT ID: $finalPatientId");
print("APPOINTMENT ID: $finalAppointmentId");

if (finalPatientId == null || finalAppointmentId == null) {
  throw Exception(
    'Erreur: patient ou rendez-vous manquant',
  );
}

final prescriptionItems = medications.map((item) {
  return {
    'medication': item.medicationController.text,
    'dosage': item.dosageController.text,
    'duration': item.durationController.text,
    'instructions': item.instructionController.text,
  };
}).toList();

final result = await PrescriptionService.createPrescription(
  patientName: widget.appointment['patient_name'],
  patientPhone: widget.appointment['patient_phone'],
  patientId: finalPatientId,
  appointmentId: finalAppointmentId,
  medication: medicationController.text.trim(),
  dosage: '',
  duration: '',
  instructions: notesController.text.trim(),
  doctorName: doctorNameController.text.trim(),
  clinicName: clinicNameController.text.trim(),
  prescriptionDate: prescriptionDateController.text.trim(),
);

    if (!mounted) return;

if (result['success'] == true) {
  final prescription = result['prescription'];

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Prescription créée'),
    ),
  );

  Navigator.pop(context, true);
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Erreur création prescription'),
    ),
  );
}



  } catch (e) {
    print("PRESCRIPTION ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Erreur: $e"),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
}
  @override
  void dispose() {
    medicationController.dispose();
    dosageController.dispose();
    durationController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Widget input({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient =
        widget.appointment['patient_name'] ?? 'Patient';
        final patientName = widget.appointment['patient_name'];
    final patientPhone = widget.appointment['patient_phone'];
    final appointmentId = widget.appointment['appointment_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Créer prescription'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
  widget.appointment['patient_name'] ?? 'Patient inconnu',
  style: const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
  ),
),

            const SizedBox(height: 20),

           Column(
  children: [

   input(
  label: 'Médicaments prescrits',
  controller: medicationController,
  maxLines: 8,
),

const SizedBox(height: 20),

input(
  label: 'Instructions',
  controller: notesController,
  maxLines: 4,
),

  ],
),

            const SizedBox(height: 14),

input(
  label: 'Nom médecin',
  controller: doctorNameController,
),

const SizedBox(height: 14),

input(
  label: 'Nom clinique',
  controller: clinicNameController,
),

const SizedBox(height: 14),

input(
  label: 'Date prescription',
  controller: prescriptionDateController,
),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : savePrescription,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
