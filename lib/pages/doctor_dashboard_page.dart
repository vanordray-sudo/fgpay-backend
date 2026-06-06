import 'package:flutter/material.dart';

import 'doctor_calendar_page.dart';
import 'doctor_unavailability_page.dart';
import 'medical_appointments_page.dart';
import 'doctor_prescription_page.dart';
import 'doctor_referrals_page.dart';
import 'doctor_appointments_page.dart';
import 'package:fgpay_clean/pages/health_professional_page.dart';
import 'package:fgpay_clean/services/professional_service.dart';
import 'health_professional_pro_page.dart';
import 'secretary_create_appointment_page.dart';
import '../services/health_service.dart';
import 'consultation_page.dart';
import 'prescriptions_page.dart';


class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});

  @override
  State<DoctorDashboardPage> createState() =>
      _DoctorDashboardPageState();
}

class _DoctorDashboardPageState
    extends State<DoctorDashboardPage> {

      String doctorName = 'Dr FG';

      Map<String, dynamic>? nextAppointment;
bool loadingNext = true;

      @override
void initState() {
  super.initState();
  _checkProfessionalStatus();
  _loadNextAppointment();
}

Future<void> _checkProfessionalStatus() async {

  final status =
      await ProfessionalService.getMyStatus();

  if (!mounted) return;

  if (status != 'approved') {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Compte professionnel en attente de validation',
        ),
      ),
    );

    Navigator.pop(context);
  }
}
Future<void> _loadNextAppointment() async {
  try {

    final data =
        await HealthService.getNextAppointment();

    if (mounted) {
      setState(() {
        nextAppointment = data['appointment'];
        loadingNext = false;
      });
    }

  } catch (_) {

    if (mounted) {
      setState(() {
        loadingNext = false;
      });
    }

  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,

      appBar: AppBar(
        backgroundColor: Colors.green,
        elevation: 0,
        title: const Text(
          'Dashboard Médecin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

     body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
            // HEADER CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Colors.green,
                    Color(0xFF0F9D58),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child:  Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

               Text(
  'Bienvenue $doctorName 👨‍⚕️',
  style: const TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  ),
),

                  SizedBox(height: 10),

                  Text(
                    'Gérez vos rendez-vous et disponibilités',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // STATS
          Row(
  children: [

    Expanded(
      child: Card(
        color: Colors.green.shade50,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const Text(
                'PROCHAIN PATIENT',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                nextAppointment?['patient_name'] ??
                    'Aucun rendez-vous',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (nextAppointment != null)
                Text(
                  '${nextAppointment!['appointment_date']} à ${nextAppointment!['appointment_time']}',
                ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: nextAppointment == null
    ? null
    : () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConsultationPage(
              appointment: nextAppointment!,
            ),
          ),
        );

        await _loadNextAppointment();
      },
                icon: const Icon(Icons.medical_services),
                label: const Text(
                  'Démarrer consultation',
                ),
              ),

            ],
          ),
        ),
      ),
    ),

    const SizedBox(width: 12),


// STATS


 const SizedBox(width: 12),

Expanded(
  child: _buildStatCard(
    title: 'Prochain patient',
    value: nextAppointment?['patient_name'] ?? '-',
    icon: Icons.person,
    color: Colors.green,
    onTap: () {},
  ),
),

                const SizedBox(width: 12),

 Expanded(
    child:  _buildStatCard(
  title: 'Patients',
  value: '8',
  icon: Icons.people,
  color: Colors.orange,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorReferralsPage(),
      ),
    );
  },
),
                ),
              ],
            ),
  
     

            const SizedBox(height: 12),

            Row(
              children: [

           Expanded(
              child:  _buildStatCard(
  title: 'Disponibles',
  value: '5',
  icon: Icons.check_circle,
  color: Colors.green,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorCalendarPage(),
      ),
    );
  },
),
                ),

                const SizedBox(width: 12),

     Expanded(
        child: _buildStatCard(
  title: 'Indispo',
  value: '2',
  icon: Icons.block,
  color: Colors.red,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DoctorUnavailabilityPage(),
      ),
    );
  },
),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // ACTIONS
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Actions rapides',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            _buildActionCard(
              context,
              title: 'Almanak médecin',
              subtitle: 'Voir disponibilités et indisponibilités',
              icon: Icons.calendar_month,
              color: Colors.green,
              page: const DoctorCalendarPage(),
            ),

            _buildActionCard(
              context,
              title: 'Ajouter indisponibilité',
              subtitle: 'Bloquer une date',
              icon: Icons.block,
              color: Colors.red,
              page: const DoctorUnavailabilityPage(),
            ),


 _buildActionCard(
  context,
  title: 'Prescriptions',
  subtitle: 'Créer ordonnances médicales',
  icon: Icons.medication,
  color: Colors.blue,
  page: const DoctorAppointmentsPage(),
),

_buildActionCard(
  context,
  title: 'Créer rendez-vous',
  subtitle: 'Planifier pour un patient',
  icon: Icons.event_available,
  color: Colors.green,
  page: const  SecretaryCreateAppointmentPage(),
),

_buildActionCard(
  context,
  title: 'Espace Professionnel',
  subtitle: 'Médecins, cliniques, laboratoires',
  icon: Icons.medical_services,
  color: Colors.green,
  page: const HealthProfessionalProPage(),
),


_buildActionCard(
  context,
  title: "Références médicales",
  subtitle: "Patients référés",
  icon: Icons.send,
  color: Colors.orange,
  page: const DoctorReferralsPage(),
),

   _buildActionCard(
  context,
  title: 'Prescriptions',
  subtitle: 'Créer ordonnances médicales',
  icon: Icons.medication,
  color: Colors.blue,
  page: const PrescriptionsPage(),
  
),        


            _buildActionCard(
  context,
  title: 'Rendez-vous patients',
  subtitle: 'Voir et gérer les rendez-vous',
  icon: Icons.calendar_month,
  color: Colors.blue,
  page: const DoctorAppointmentsPage(),
),




            const SizedBox(height: 25),

            // UPCOMING
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Prochains rendez-vous',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            _buildAppointmentCard(
              patient: 'James Constant',
              date: '14/05/2026',
              hour: '08:00',
            ),

            _buildAppointmentCard(
              patient: 'Marie Pierre',
              date: '14/05/2026',
              hour: '10:00',
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  VoidCallback? onTap,
}) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(title),
            ],
          ),
        ),
      ),
    ),
  );
}
Widget _buildActionCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required Color color,
  required Widget page,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildAppointmentCard({
    required String patient,
    required String date,
    required String hour,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [

          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.green.withOpacity(0.15),
            child: const Icon(
              Icons.person,
              color: Colors.green,
            ),
          ),

          const SizedBox(width: 15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [


                Text(
                  patient,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 5),

                Text('$date à $hour'),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Text(
              'Confirmé',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}