import 'package:flutter/material.dart';
import '../services/health_service.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {

  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final genderController = TextEditingController();
  final dateOfBirthController = TextEditingController();
  final bloodGroupController = TextEditingController();
  final allergiesController = TextEditingController();
  final chronicDiseasesController = TextEditingController();
  final emergencyContactNameController = TextEditingController();
  final emergencyContactPhoneController = TextEditingController();
  final addressController = TextEditingController();

  

  bool _isLoading = true;


  @override
void initState() {
  super.initState();
  _loadProfile();
}

Future<void> _loadProfile() async {
  final profile = await HealthService.getPatientProfile();

  if (profile != null) {
  fullNameController.text = profile['full_name'] ?? '';
  phoneController.text = profile['phone'] ?? '';
  genderController.text = profile['gender'] ?? '';

  dateOfBirthController.text =
      profile['date_of_birth'] ?? '';

  bloodGroupController.text =
      profile['blood_group'] ?? '';

  allergiesController.text =
      profile['allergies'] ?? '';

  chronicDiseasesController.text =
      profile['chronic_diseases'] ?? '';

  emergencyContactNameController.text =
      profile['emergency_contact_name'] ?? '';

  emergencyContactPhoneController.text =
      profile['emergency_contact_phone'] ?? '';

  addressController.text =
      profile['address'] ?? '';
}

  setState(() {
    _isLoading = false;
  });
}


  Future<void> saveProfile() async {

    setState(() {
      _isLoading = true;
    });

    try {

      final result = await HealthService.savePatientProfile(
        fullName: fullNameController.text,
        phone: phoneController.text,
        gender: genderController.text,
        dateOfBirth: dateOfBirthController.text,
        bloodGroup: bloodGroupController.text,
        allergies: allergiesController.text,
        chronicDiseases: chronicDiseasesController.text,
        emergencyContactName:
            emergencyContactNameController.text,
        emergencyContactPhone:
            emergencyContactPhoneController.text,
        address: addressController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Profil enregistré',
          ),
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
        ),
      );

    } finally {

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
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
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

if (_isLoading) {
  return const Scaffold(
    body: Center(
      child: CircularProgressIndicator(),
    ),
  );
}

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil médical patient'),
        backgroundColor: Colors.green,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            buildField(
              'Nom complet',
              fullNameController,
            ),

            buildField(
              'Téléphone',
              phoneController,
            ),

            buildField(
              'Genre',
              genderController,
            ),

            buildField(
              'Date de naissance',
              dateOfBirthController,
            ),

            buildField(
              'Groupe sanguin',
              bloodGroupController,
            ),

            buildField(
              'Allergies',
              allergiesController,
              maxLines: 3,
            ),

            buildField(
              'Maladies chroniques',
              chronicDiseasesController,
              maxLines: 3,
            ),

            buildField(
              'Nom contact urgence',
              emergencyContactNameController,
            ),

            buildField(
              'Téléphone urgence',
              emergencyContactPhoneController,
            ),

            buildField(
              'Adresse',
              addressController,
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : saveProfile,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),

                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text(
                        'Enregistrer profil médical',
                        style: TextStyle(
                          fontSize: 16,
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