import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_service.dart';

class AddAppointmentPage extends StatefulWidget {
  const AddAppointmentPage({super.key});

  @override
  State<AddAppointmentPage> createState() => _AddAppointmentPageState();
}

class _AddAppointmentPageState extends State<AddAppointmentPage> {
  final patientPhoneController = TextEditingController();
  final patientNameController = TextEditingController();
  final doctorNameController = TextEditingController();
  final clinicNameController = TextEditingController();
  final dateController = TextEditingController();
  final timeController = TextEditingController();
  final reasonController = TextEditingController();

  bool isLoading = false;

Future<void> saveAppointment() async {
  if (dateController.text.trim().isEmpty ||
      timeController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mete date ak heure rendez-vous la')),
    );
    return;
  }

  try {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/appointments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'patientPhone': patientPhoneController.text.trim(),
        'patientName': patientNameController.text.trim(),
        'doctorName': doctorNameController.text.trim(),
        'clinicName': clinicNameController.text.trim(),
        'appointmentDate': dateController.text.trim(),
        'appointmentTime': timeController.text.trim(),
        'reason': reasonController.text.trim(),
      }),
    );

    final data = jsonDecode(response.body);
    print('APPOINTMENT RESULT = $data');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rendez-vous créé avec succès')),
    );

    Navigator.pop(context, true);
  } catch (e) {
    print('SAVE APPOINTMENT ERROR: $e');
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter rendez-vous'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildField(controller: patientPhoneController, label: 'Téléphone patient'),
            buildField(controller: patientNameController, label: 'Nom patient'),
            buildField(controller: doctorNameController, label: 'Nom médecin'),
            buildField(controller: clinicNameController, label: 'Nom clinique'),
            buildField(controller: dateController, label: 'Date rendez-vous ex: 07/05/2026'),
            buildField(controller: timeController, label: 'Heure ex: 14:30'),
            buildField(controller: reasonController, label: 'Motif', maxLines: 4),

            const SizedBox(height: 20),
          
            SizedBox(
              width: double.infinity,
              height: 55,
             child: ElevatedButton(
  onPressed: () {
    print('BUTTON CLICKED');
    saveAppointment();
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
  ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Enregistrer rendez-vous',
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}