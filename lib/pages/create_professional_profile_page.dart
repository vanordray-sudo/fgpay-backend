import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


class CreateProfessionalProfilePage extends StatefulWidget {
  const CreateProfessionalProfilePage({super.key});

  @override
  State<CreateProfessionalProfilePage> createState() =>
      _CreateProfessionalProfilePageState();
}

class _CreateProfessionalProfilePageState
    extends State<CreateProfessionalProfilePage> {
bool isSaving = false;

  final nameController = TextEditingController();
  final specialtyController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final orderNumberController = TextEditingController();
  final clinicController = TextEditingController();

  PlatformFile? pickedFile;
String fileName = "Aucun fichier";

Future<void> pickDocument() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'jpg', 'png'],
    withData: true,
  );

  if (result != null) {
    setState(() {
      pickedFile = result.files.single;
      fileName = result.files.single.name;
    });
  }
}

  @override
  void dispose() {
    nameController.dispose();
    specialtyController.dispose();
    phoneController.dispose();
    addressController.dispose();
    orderNumberController.dispose();
    clinicController.dispose();
    super.dispose();
  }

  Widget buildField({
    required TextEditingController controller,
    required String label,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

 String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:3000';
  } else {
    return 'http://10.0.2.2:3000';
  }
} 

Future<void> saveProfile() async {

  if (isSaving) return;

  setState(() {
    isSaving = true;
  });

  try {

    if (pickedFile == null || pickedFile!.bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ajoute yon dokiman anvan"),
        ),
      );

      setState(() {
        isSaving = false;
      });

      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');



var request = http.MultipartRequest(
  'POST',
  Uri.parse('$baseUrl/api/professionals/create'),
);

request.headers['Authorization'] =
    'Bearer $token';

  request.fields['name'] = nameController.text;
  request.fields['specialty'] = specialtyController.text;
  request.fields['phone'] = phoneController.text;
  request.fields['address'] = addressController.text;
  request.fields['order_number'] =
      orderNumberController.text;
  request.fields['clinic'] =
      clinicController.text;

  request.files.add(
  http.MultipartFile.fromBytes(
    'document',
    pickedFile!.bytes!,
    filename: pickedFile!.name,
  ),
);

  var response = await request.send();
  final responseBody = await response.stream.bytesToString();

print("STATUS: ${response.statusCode}");
print("BODY: $responseBody");

 if (response.statusCode == 200) {

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        "Pwofil voye bay Admin Santé avèk siksè",
      ),
    ),
  );

} else {

  print("UPLOAD ERROR");

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        "Erè: $responseBody",
      ),
    ),
  );
}
 } catch (e) {
    print(e);
  } finally {
    if (mounted) {
      setState(() {
        isSaving = false;
      });
    }
  }

}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer profil professionnel'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            buildField(controller: nameController, label: 'Nom complet'),
            buildField(controller: specialtyController, label: 'Spécialité'),
            buildField(controller: phoneController, label: 'Téléphone'),
            buildField(controller: addressController, label: 'Adresse'),
            buildField(controller: orderNumberController, label: 'Numéro d’ordre'),
            buildField(controller: clinicController, label: 'Clinique'),

           

            const SizedBox(height: 20),

            Card(
  child: ListTile(
    leading: const Icon(Icons.upload_file),
    title: Text(fileName),
    subtitle: const Text('Ajouter diplôme / licence / CIN'),
    onTap: pickDocument,
  ),
),

const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: saveProfile,
                icon: const Icon(Icons.check_circle),
                label: const Text('Soumettre pour validation'),
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