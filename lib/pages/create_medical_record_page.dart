import 'package:flutter/material.dart';

import '../services/medical_record_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../services/referral_service.dart';
import '../config/api_config.dart';

class CreateMedicalRecordPage extends StatefulWidget {
  final dynamic appointment;

  const CreateMedicalRecordPage({
    super.key,
    this.appointment,
  });

  @override
  State<CreateMedicalRecordPage> createState() =>
      _CreateMedicalRecordPageState();
}

class _CreateMedicalRecordPageState
    extends State<CreateMedicalRecordPage> {

  PlatformFile? selectedFile;
  Uint8List? previewBytes;

  final titleController = TextEditingController();
final typeController = TextEditingController();
final descriptionController = TextEditingController();
final patientIdController = TextEditingController();
final doctorNameController = TextEditingController();
final clinicNameController = TextEditingController();

int? patientId;
int? appointmentId;



 @override
void initState() {
  super.initState();

  if (widget.appointment != null) {
    patientId =
    widget.appointment?['patient_id'] ??
    widget.appointment?['user_id'] ??
    widget.appointment?['patientId'];

appointmentId =
    widget.appointment?['appointment_id'] ??
    widget.appointment?['id'];

    patientIdController.text =
        widget.appointment['patient_name']?.toString() ?? '';

    doctorNameController.text =
        widget.appointment['doctor_name']?.toString() ?? 'Dr James Constant';

    titleController.text =
        widget.appointment['reason']?.toString() ?? '';
  }

  print('MEDICAL RECORD PATIENT ID: $patientId');
  print('MEDICAL RECORD APPOINTMENT ID: $appointmentId');
}

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
  }) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    ),
  );
}

  bool loading = false;

  Future<void> createRecord() async {
  setState(() {
    loading = true;
  });

print('TITLE: ${titleController.text}');
print('TYPE: ${typeController.text}');
print('DESC: ${descriptionController.text}');
print('FILE: ${selectedFile?.name}');

  try {
   final success = await MedicalRecordService.createRecord(
  patientId: 3,
  title: titleController.text,
  type: typeController.text,
  description: descriptionController.text,
  doctorName: doctorNameController.text,
  clinicName: clinicNameController.text,
  file: selectedFile,
);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Résultat ajouté' : 'Erreur ajout résultat',
        ),
      ),
    );
  } catch (e) {
    print('CREATE RECORD FLUTTER ERROR: $e');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erreur ajout résultat')),
    );
  } finally {
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }
}
void showReferralPopup() {
  final reasonController =
      TextEditingController();

  int? specialtyId;

  showDialog(
    context: context,

    builder: (context) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(24),
            ),

            title: const Text(
              'Référence médicale',
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,

              children: [

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
    DropdownMenuItem(value: 23, child: Text('Infirmier (e)')),
    DropdownMenuItem(value: 24, child: Text('Aide-soignant(e)')),
    DropdownMenuItem(value:25, child: Text('Chirurgien')),
    
  ],
  onChanged: (value) {
    setStateDialog(() {
      specialtyId = value;
    });
  },
),
                const SizedBox(height: 16),

                TextField(
                  controller: reasonController,
                  maxLines: 3,

                  decoration:
                      const InputDecoration(
                    hintText: 'Raison',
                  ),
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
    if (specialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez choisir une spécialité')),
      );
      return;
    }

    try {
      await ReferralService.createReferral(
        patientId: patientId ?? 0,
        specialtyId: specialtyId!,
        reason: reasonController.text.trim(),
        priority: 'normal',
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Référence envoyée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  },
  child: const Text('Envoyer'),
             ),
                
            ],
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: AppBar(
  title: const Text('Ajouter résultat médical'),
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: ListView(
          children: [

  _input(patientIdController, 'Nom patient'),

_input(titleController, 'Titre analyse'),

_input(typeController, 'Catégorie'),

_input(
  descriptionController,
  'Notes médicales',
  maxLines: 4,
),

_input(doctorNameController, 'Nom médecin'),

_input(clinicNameController, 'Nom clinique'),


SizedBox(
  width: double.infinity,

  child: OutlinedButton.icon(
    onPressed: () async {
      final result =
          await FilePicker.platform.pickFiles();

     if (result != null) {
  setState(() {
    selectedFile = result.files.first;
    previewBytes = result.files.first.bytes;
  });
}
    },

    icon: const Icon(Icons.upload_file),

    label: Text(
      selectedFile == null
          ? 'Choisir fichier'
          : selectedFile!.name,
    ),

    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.green,

      side: const BorderSide(
        color: Colors.green,
      ),

      padding: const EdgeInsets.symmetric(
        vertical: 18,
      ),

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
    ),
  ),
),

const SizedBox(height: 20),

if (selectedFile != null)
  Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.green.shade100),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aperçu fichier',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 12),

        if (previewBytes != null &&
            ['jpg', 'jpeg', 'png'].contains(
              selectedFile!.extension?.toLowerCase(),
            ))
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(
              previewBytes!,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else if (selectedFile!.extension?.toLowerCase() == 'pdf')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade100),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedFile!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            selectedFile!.name,
          ),
      ],
    ),
  ),
const SizedBox(height: 18),

SizedBox(
  width: double.infinity,
  height: 52,
  child: OutlinedButton.icon(
    onPressed: showReferralPopup,
    icon: const Icon(Icons.send),
    label: const Text('Référer ce patient'),
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.orange,
      side: const BorderSide(color: Colors.orange),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  ),
),

const SizedBox(height: 16),

SizedBox(
  width: double.infinity,
  height: 55,

  child: ElevatedButton(
    onPressed:
        loading ? null : createRecord,

    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,

      foregroundColor: Colors.white,

      elevation: 3,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(24),
      ),
    ),

    child: Text(
      loading
          ? 'Chargement...'
          : 'Ajouter résultat',

      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
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