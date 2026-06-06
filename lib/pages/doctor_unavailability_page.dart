import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../services/auth_service.dart';

class DoctorUnavailabilityPage extends StatefulWidget {
  const DoctorUnavailabilityPage({super.key});

  @override
  State<DoctorUnavailabilityPage> createState() =>
      _DoctorUnavailabilityPageState();
}

class _DoctorUnavailabilityPageState
    extends State<DoctorUnavailabilityPage> {
  final _doctorController = TextEditingController();
  final _clinicController = TextEditingController();
  final _dateController = TextEditingController();
  final _reasonController = TextEditingController();

  bool _loading = false;

 Future<void> _saveUnavailability() async {
  setState(() => _loading = true);

  try {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/api/health/doctor-unavailability'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'doctor_name': _doctorController.text.trim(),
        'clinic_name': _clinicController.text.trim(),
        'unavailable_date': _dateController.text.trim(),
        'reason': _reasonController.text.trim(),
      }),
    );

    print(response.body);

    final data = jsonDecode(response.body);

    if (!mounted) return;

    if (response.statusCode == 200 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indisponibilité enregistrée')),
      );

      _doctorController.clear();
      _clinicController.clear();
      _dateController.clear();
      _reasonController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Erreur serveur')),
      );
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }

  if (mounted) {
    setState(() => _loading = false);
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indisponibilité médecin'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _doctorController,
              decoration: const InputDecoration(
                labelText: 'Nom médecin',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _clinicController,
              decoration: const InputDecoration(
                labelText: 'Clinique',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'Date ex: 2026-05-20',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Raison',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveUnavailability,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Enregistrer indisponibilité',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}