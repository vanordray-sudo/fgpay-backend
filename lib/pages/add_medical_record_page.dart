import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../services/referral_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AddMedicalRecordPage extends StatefulWidget {

  final int patientId;
  final String defaultCategory;
final String pageTitle;
final String? patientPhone;
final String? doctorName;
final String? clinicName;

  const AddMedicalRecordPage({
  super.key,
  required this.patientId,
  this.defaultCategory = 'Analyse',
  this.pageTitle = 'Ajouter résultat médical',
  this.patientPhone,
  this.doctorName,
  this.clinicName,
});

  @override
  State<AddMedicalRecordPage> createState() =>
      _AddMedicalRecordPageState();
}

class _AddMedicalRecordPageState
    extends State<AddMedicalRecordPage> {

  final patientPhoneController = TextEditingController();
  final titleController = TextEditingController();
  final categoryController = TextEditingController();
  final notesController = TextEditingController();
  final doctorNameController = TextEditingController();
  final clinicNameController = TextEditingController();

  @override
void initState() {
  super.initState();

  categoryController.text = widget.defaultCategory;
  patientPhoneController.text = widget.patientPhone ?? '';
  doctorNameController.text = widget.doctorName ?? 'Dr James Constant';
  clinicNameController.text = widget.clinicName ?? 'FG Centre de Santé';
}

  PlatformFile? selectedFile;
  String? selectedFileName;

  bool isLoading = false;



  Future<void> showReferralDialog() async {

  final reasonController =
      TextEditingController();

  int specialtyId = 2;

  await showDialog(
    context: context,
    builder: (_) {
      return AlertDialog(

        title: const Text(
          'Référence médicale',
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            DropdownButtonFormField<int>(
              value: specialtyId,

              items: const [

                DropdownMenuItem(
                  value: 1,
                  child: Text('Médecin généraliste'),
                ),

                DropdownMenuItem(
                  value: 2,
                  child: Text('Cardiologue'),
                ),

                DropdownMenuItem(
                  value: 3,
                  child: Text('Dermatologue'),
                ),
              ],

              onChanged: (v) {
                specialtyId = v!;
              },
            ),

            const SizedBox(height: 15),

            TextField(
              controller: reasonController,

              decoration: const InputDecoration(
                labelText: 'Raison',
                border: OutlineInputBorder(),
              ),

              maxLines: 3,
            ),
          ],
        ),

        actions: [

          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },

            child: const Text('Annuler'),
          ),

          ElevatedButton(
            onPressed: () async {

           await ReferralService.createReferral(
  patientId: widget.patientId,
  specialtyId: specialtyId!,
  reason: reasonController.text.trim(),
  priority: 'normal',
);

              Navigator.pop(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(

                const SnackBar(
                  content: Text(
                    'Référence envoyée',
                  ),
                ),
              );
            },

            child: const Text('Envoyer'),
          ),
        ],
      );
    },
  );
}

 Future<void> saveRecord() async {
  setState(() {
    isLoading = true;
  });

  try {
  final result = await HealthService.addMedicalRecord(
  patientPhone: patientPhoneController.text.trim(),
  title: titleController.text.trim(),
  category: categoryController.text.trim(),
  notes: notesController.text.trim(),
  doctorName: doctorNameController.text.trim(),
  clinicName: clinicNameController.text.trim(),
  file: selectedFile,
  patientId: widget.patientId,
);

print('SAVE RESULT: $result');

if (!mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(result['message'] ?? result.toString()),
  ),
);
  } catch (e) {
  print('SAVE RECORD ERROR: $e');

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('Erreur: $e'),
    ),
  );

  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
      });
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
  final isJustification =
      widget.defaultCategory == 'Pièce justificative';

  return Scaffold(
    appBar: AppBar(
      title: Text(widget.pageTitle),
    ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [

           
             if (!isJustification)
  buildField(
    controller: patientPhoneController,
    label: 'Téléphone patient',
  ),

buildField(
  controller: titleController,
  label: isJustification ? 'Titre document' : 'Titre analyse',
),

buildField(
  controller: categoryController,
  label: 'Catégorie',
),

buildField(
  controller: notesController,
  label: isJustification ? 'Description' : 'Notes médicales',
  maxLines: isJustification ? 3 : 5,
),

if (!isJustification)
  buildField(
    controller: doctorNameController,
    label: 'Nom médecin',
  ),

buildField(
  controller: clinicNameController,
  label: 'Nom clinique',
),
            

OutlinedButton.icon(
  icon: const Icon(Icons.attach_file),
  label: Text(selectedFileName ?? 'Choisir fichier PDF'),
  onPressed: () async {
   
    final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
  withData: true,
);

if (result != null && result.files.isNotEmpty) {
  setState(() {
    selectedFile = result.files.first;
    selectedFileName = selectedFile!.name;
  });
}
  },
),

            const SizedBox(height: 20),

ElevatedButton.icon(
  icon: const Icon(Icons.send),
  label: const Text('Référer ce patient'),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.orange,
    padding: const EdgeInsets.symmetric(
      horizontal: 20,
      vertical: 14,
    ),
  ),
  onPressed: () {
    showReferralDialog();
  },
),

const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: isLoading ? null : saveRecord,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),

                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}