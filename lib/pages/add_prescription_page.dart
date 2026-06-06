import 'package:flutter/material.dart';
import '../services/health_service.dart';

class AddPrescriptionPage extends StatefulWidget {
  const AddPrescriptionPage({super.key});

  @override
  State<AddPrescriptionPage> createState() => _AddPrescriptionPageState();
}

class _AddPrescriptionPageState extends State<AddPrescriptionPage> {
 final patientIdController = TextEditingController();

final medicationController = TextEditingController();
final dosageController = TextEditingController();
final durationController = TextEditingController();
final instructionsController = TextEditingController();
final doctorNameController = TextEditingController();

final clinicNameController = TextEditingController(
  text: 'FG Centre de Santé',
);

  bool isLoading = false;

 Future<void> savePrescription() async {
  setState(() => isLoading = true);

  try {
   final result = await HealthService.addPrescription(
  patientId: '4',
  medication: medicationController.text.trim(),
  dosage: dosageController.text.trim(),
  duration: durationController.text.trim(),
  instructions: instructionsController.text.trim(),
  doctorName: doctorNameController.text.trim(),
  clinicName: clinicNameController.text.trim(),
);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result['message'] ?? 'Prescription enregistrée',
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $e'),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);
    }
  }
} 
  Widget buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer prescription'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
           buildField(
  controller: patientIdController,
  label: 'ID Patient',
),

buildField(
  controller: medicationController,
  label: 'Médicament',
),

buildField(
  controller: dosageController,
  label: 'Dosage',
),

buildField(
  controller: durationController,
  label: 'Durée',
),

buildField(
  controller: instructionsController,
  label: 'Instructions',
  maxLines: 4,
),

buildField(
  controller: doctorNameController,
  label: 'Nom médecin',
),

buildField(
  controller: clinicNameController,
  label: 'Nom clinique',
),
           const SizedBox(height: 20),

SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: isLoading ? null : savePrescription,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    child: Text(
      isLoading
          ? 'Chargement...'
          : 'Enregistrer prescription',
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}