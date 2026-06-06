import 'package:flutter/material.dart';
import '../services/referral_service.dart';

class CreatePatientReferralPage extends StatefulWidget {
  const CreatePatientReferralPage({super.key});

  @override
  State<CreatePatientReferralPage> createState() =>
      _CreatePatientReferralPageState();
}

class _CreatePatientReferralPageState
    extends State<CreatePatientReferralPage> {
  int? specialtyId;

  final patientNameController = TextEditingController();
  final reasonController = TextEditingController();

  @override
  void dispose() {
    patientNameController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  Future<void> sendReferral() async {
    if (specialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une spécialité')),
      );
      return;
    }

    if (patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le nom du patient')),
      );
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le motif')),
      );
      return;
    }

    try {
     await ReferralService.createReferral(
  patientId: 1,
  specialtyId: specialtyId!,
  reason: reasonController.text.trim(),
  priority: 'normal',
);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Référence envoyée avec succès')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }
String getSpecialtyName(int id) {
  switch (id) {
    case 1:
      return 'Cardiologue';

    case 2:
      return 'Dentiste';

    case 3:
      return 'Pédiatre';

    default:
      return '';
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Référer un patient'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: patientNameController,
              decoration: const InputDecoration(
                labelText: 'Nom patient',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: specialtyId,
              decoration: const InputDecoration(
                labelText: 'Spécialité',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Cardiologue')),
                DropdownMenuItem(value: 2, child: Text('Dentiste')),
                DropdownMenuItem(value: 3, child: Text('Pédiatre')),
              ],
              onChanged: (value) {
                setState(() {
                  specialtyId = value;
                });
              },
            ),

            const SizedBox(height: 16),

            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motif',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: sendReferral,
                child: const Text('Envoyer référence'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}