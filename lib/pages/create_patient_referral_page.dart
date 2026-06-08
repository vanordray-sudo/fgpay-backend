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
                 DropdownMenuItem(value: 1, child: Text('Généraliste')),
                      DropdownMenuItem(value: 2, child: Text('Cardiologue')),
                      DropdownMenuItem(value: 3, child: Text('Dermatologue')),
                      DropdownMenuItem(value: 4, child: Text('Neurologue')),
                      DropdownMenuItem(value: 5, child: Text('Pédiatre')),
                      DropdownMenuItem(value: 6, child: Text('Orthopédiste')),
                      DropdownMenuItem(value: 7, child: Text('Gynécologue')),
                      DropdownMenuItem(value: 8, child: Text('Ophtalmologue')),
                      DropdownMenuItem(value: 9, child: Text('ORL')),
                      DropdownMenuItem(value: 10, child: Text('Psychiatre')),
                      DropdownMenuItem(value: 11, child: Text('Radiologue')),
                      DropdownMenuItem(value: 12, child: Text('Oncologue')),
                      DropdownMenuItem(value: 13, child: Text('Urologue')),
                      DropdownMenuItem(value: 14, child: Text('Diabétologue')),
                      DropdownMenuItem(value: 15, child: Text('Pneumologue')),
                      DropdownMenuItem(value: 16, child: Text('Rhumatologue')),
                      DropdownMenuItem(value: 17, child: Text('Endocrinologue')),
                      DropdownMenuItem(value: 18, child: Text('Dentiste')),
                      DropdownMenuItem(value: 19, child: Text('Kinésithérapeute')),
                      DropdownMenuItem(value: 20, child: Text('Néphrologue')),
                      DropdownMenuItem(value: 21, child: Text('Nutritionniste')),
                      DropdownMenuItem(value: 22, child: Text('Infectionniste')),
                       DropdownMenuItem(value: 23, child: Text('Allergologue')),
                        DropdownMenuItem(value: 24, child: Text('Sexologue')),
                      DropdownMenuItem(value: 25, child: Text('Toxicologue')),
                      DropdownMenuItem(value: 26, child: Text('Pneumologue')),
                      DropdownMenuItem(value: 27, child: Text('Immunologue')),
                      DropdownMenuItem(value: 28, child: Text('Cancérologue')),
                      DropdownMenuItem(value: 29, child: Text('Anesthésiste')),
                      DropdownMenuItem(value: 30, child: Text('Algologue')),
                       DropdownMenuItem(value: 31, child: Text('Addictologue')),
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