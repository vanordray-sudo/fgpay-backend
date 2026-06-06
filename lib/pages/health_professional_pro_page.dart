import 'package:flutter/material.dart';

import 'create_medical_record_page.dart';
import 'doctor_availability_page.dart';
import 'doctor_unavailability_page.dart';
import 'doctor_referrals_page.dart';
import 'package:fgpay_clean/pages/create_patient_referral_page.dart';
import 'patient_prescriptions_page.dart';
import 'prescriptions_page.dart';



class HealthProfessionalProPage extends StatefulWidget {
  const HealthProfessionalProPage({super.key});

  @override
  State<HealthProfessionalProPage> createState() =>
      _HealthProfessionalProPageState();
}

class _HealthProfessionalProPageState
    extends State<HealthProfessionalProPage> {

  final Map<String, dynamic> user = {
    'name': 'Dr. James Constant',
    'specialty': 'Médecin généraliste',
    'clinic': 'FG Centre de Santé',
    'professional_status': 'approved',
  };

  Widget _proCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = Colors.green,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool approved =
        user['professional_status'] == 'approved';

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
              margin: const EdgeInsets.only(bottom: 18),
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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['name'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['specialty'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user['clinic'],
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                approved
                                    ? Icons.verified
                                    : Icons.pending,
                                color: approved
                                    ? Colors.green
                                    : Colors.orange,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                approved
                                    ? 'Compte approuvé'
                                    : 'Validation en attente',
                                style: TextStyle(
                                  color: approved
                                      ? Colors.green
                                      : Colors.orange,
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

            if (!approved)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.orange),
                ),
                child: const Text(
                  'Votre compte professionnel est en attente de validation FG Santé. Certaines actions sont désactivées.',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

           _proCard(
  icon: Icons.upload_file,
  title: 'Ajouter résultat médical',
  subtitle: 'Créer un résultat et joindre un PDF',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMedicalRecordPage(),
      ),
    );
  },
),
                  
                
  _proCard(
  icon: Icons.description,
  title: 'Mes prescriptions créées',
  subtitle: 'Imprimer, signer et envoyer au patient',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
         builder: (_) => const PrescriptionsPage(),
      ),
    );
  },
),
            


            _proCard(
              icon: Icons.send,
              title: 'Référer un patient',
              subtitle: 'Envoyer un patient vers un spécialiste',
              onTap: () {
                Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const CreatePatientReferralPage(),
  ),
);
              },
            ),

            _proCard(
              icon: Icons.calendar_month,
              title: 'Gérer disponibilités',
              subtitle: 'Définir les jours de consultation',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DoctorAvailabilityPage(),
                  ),
                );
              },
            ),



            _proCard(
              icon: Icons.event_busy,
              title: 'Déclarer indisponibilité',
              subtitle: 'Bloquer une date où le médecin ne reçoit pas',
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DoctorUnavailabilityPage(),
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