import 'package:flutter/material.dart';
import 'add_medical_record_page.dart';
import 'add_prescription_page.dart';
import 'doctor_availability_page.dart';
import 'doctor_availability_list_page.dart';
import 'doctor_calendar_page.dart';
import 'doctor_unavailability_page.dart';
import 'doctor_referrals_page.dart';
import '../services/referral_service.dart';
import 'create_medical_record_page.dart';
import '../services/medical_record_service.dart';
import 'prescriptions_page.dart';
import 'professional_profile_page.dart';

class HealthProfessionalPage extends StatefulWidget {
  const HealthProfessionalPage({super.key});

  @override
  State<HealthProfessionalPage> createState() =>
      _HealthProfessionalPageState();
}

class _HealthProfessionalPageState
    extends State<HealthProfessionalPage> {

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> user = {
      'professional_status': 'approved',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Espace Professionnel'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // header/badge/proCard yo isit
          ],
        ),
      ),
    );
  

  Widget _proCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

 void showReferralDialog(BuildContext context) {
  final patientIdController = TextEditingController();
  final reasonController = TextEditingController();

  int? specialtyId;
  String priority = 'normal';

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Référer ce patient'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: patientIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID Patient',
                      border: OutlineInputBorder(),
                    ),
                  ),
              

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
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

                    ],
                    onChanged: (value) {
                      setState(() {
                        specialtyId = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      DropdownMenuItem(value: 'critique', child: Text('Critique')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        priority = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Raison',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final patientId = int.tryParse(patientIdController.text.trim());

                  if (patientId == null || specialtyId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Choisissez patient et spécialité'),
                      ),
                    );
                    return;
                  }

                  final result = await ReferralService.createReferral(
                    patientId: patientId,
                    specialtyId: specialtyId!,
                    reason: reasonController.text.trim(),
                    priority: priority,
                  );

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        result['success'] == true
                            ? 'Référence envoyée'
                            : 'Erreur envoi référence',
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
    },
  );
}


@override
Widget build(BuildContext context) {
  final Map<String, dynamic> user = {
    'professional_status': 'approved',
  };

  final bool approved = user['professional_status'] == 'approved';

  return Scaffold(
    appBar: AppBar(
      title: const Text('Espace Professionnel'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade400,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. James Constant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        approved
                            ? 'Professionnel vérifié FG Santé'
                            : 'Validation en attente',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              approved ? Icons.verified : Icons.pending,
                              color: approved ? Colors.green : Colors.orange,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              approved
                                  ? 'Compte approuvé'
                                  : 'En attente',
                              style: TextStyle(
                                color:
                                    approved ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),


 
const SizedBox(height: 20),
            _proCard(
              icon: Icons.upload_file,
              title: 'Ajouter résultat médical',
              subtitle: 'Envoyer analyse, radio, scanner, document',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMedicalRecordPage(
                      patientId: 3,
                    ),
                  ),
                );
              },
            ),

            _proCard(
              icon: Icons.medication,
              title: 'Créer prescription',
              subtitle: 'Ordonnance et traitement pour un patient',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddPrescriptionPage(),
                  ),
                );
              },
            ),

            _proCard(
              icon: Icons.send,
              title: 'Référer ce patient',
              subtitle: 'Envoyer un patient vers un spécialiste',
              onTap: () {
                showReferralDialog(context);
              },
            ),

            _proCard(
              icon: Icons.event_available,
              title: 'Voir calendrier médecin',
              subtitle: 'Consulter les disponibilités enregistrées',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorAvailabilityListPage(),
                  ),
                );
              },
            ),

            _proCard(
              icon: Icons.assignment,
              title: 'Références médicales',
              subtitle: 'Voir patients référés',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorReferralsPage(),
                  ),
                );
              },
            ),

_proCard(
  icon: Icons.upload_file,
  title: 'Ajouter résultat médical',
  subtitle: 'Envoyer analyse, radio, scanner, document',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  CreateMedicalRecordPage(),
      ),
    );
  },
),



          _proCard(
            icon: Icons.event_busy,
            title: 'Déclarer indisponibilité',
            subtitle: 'Bloquer une date où le médecin ne reçoit pas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DoctorUnavailabilityPage(),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
  }
    }

  
    
    
    
        
     

  
    

    
    
     