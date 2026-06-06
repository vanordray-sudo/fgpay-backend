import 'package:flutter/material.dart';

class PatientMedicalProfilePage extends StatefulWidget {
  const PatientMedicalProfilePage({super.key});

  @override
  State<PatientMedicalProfilePage> createState() =>
      _PatientMedicalProfilePageState();
}

class _PatientMedicalProfilePageState extends State<PatientMedicalProfilePage> {
  final bloodGroupController = TextEditingController();
  final allergiesController = TextEditingController();
  final chronicDiseasesController = TextEditingController();
  final treatmentsController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final notesController = TextEditingController();

  @override
  void dispose() {
    bloodGroupController.dispose();
    allergiesController.dispose();
    chronicDiseasesController.dispose();
    treatmentsController.dispose();
    emergencyContactController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Widget field({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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

  void saveProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil médical enregistré'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil médical'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            field(
              label: 'Groupe sanguin',
              controller: bloodGroupController,
            ),
            field(
              label: 'Allergies',
              controller: allergiesController,
              maxLines: 2,
            ),
            field(
              label: 'Maladies chroniques',
              controller: chronicDiseasesController,
              maxLines: 2,
            ),
            field(
              label: 'Traitements actuels',
              controller: treatmentsController,
              maxLines: 2,
            ),
            field(
              label: 'Contact urgence',
              controller: emergencyContactController,
            ),
            field(
              label: 'Notes médicales',
              controller: notesController,
              maxLines: 4,
            ),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}