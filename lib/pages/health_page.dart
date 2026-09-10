import 'package:flutter/material.dart';
import 'prescriptions_page.dart';
import 'appointments_page.dart';
import 'health_professional_page.dart';
import 'health_patient_page.dart';
import 'patient_profile_page.dart';
import 'add_medical_record_page.dart';
import 'medical_record_page.dart';
import 'patient_records_page.dart';
import 'add_appointment_page.dart';
import 'health_professional_page.dart';
import 'my_appointments_page.dart';
import 'doctor_dashboard_page.dart';
import 'patient_medical_profile_page.dart';
import 'medical_results_page.dart';
import 'patient_referrals_page.dart';
import 'doctor_referrals_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_professionals_page.dart';
import 'professional_profile_page.dart';
import 'create_professional_profile_page.dart';
import 'admin_professional_validation_page.dart';
import 'admin_medical_documents_page.dart';
import 'admin_prescriptions_page.dart';
import '../services/health_service.dart';
import '../services/auth_service.dart';
import 'validation_professionals_page.dart';
import 'subscription_page.dart';
import 'admin_notifications_page.dart';
import 'doctor_appointments_page.dart';
import 'login_page.dart';
import 'fgsante_subscription_page.dart';




class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  int doctorsCount = 0;
  int resultsCount = 0;
  int appointmentsCount = 0;
  int prescriptionsCount = 0;

  bool isLoading = true;

String role = 'patient';
String userName = 'Utilisateur';

  @override
void initState() {
  super.initState();
  loadUserData();
  loadStats();
}

Future<void> loadUserData() async {
  final userRole = await AuthService.getHealthRole();
  final user = await AuthService.getUser();

  
print('HEALTH USER = $user');

 setState(() {
  role = userRole;
  userName = user?['full_name'] ?? user?['name'] ?? 'Utilisateur';
}); 
}

  Future<void> loadStats() async {
  try {
    print('LOAD STATS CALLED');

    final stats = await HealthService.getHealthStats();

    print('STATS RESULT = $stats');

    setState(() {
      doctorsCount = stats['doctors'] ?? 0;
      resultsCount = stats['results'] ?? 0;
      appointmentsCount = stats['appointments'] ?? 0;
      prescriptionsCount = stats['prescriptions'] ?? 0;

      isLoading = false;
    });
  } catch (e) {
    print('Erreur chargement stats santé: $e');

    setState(() {
      isLoading = false;
    });
  }
}

Widget _healthCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 320,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          height: 140,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.green.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: Colors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
  subtitle,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    color: Colors.grey.shade600,
    fontSize: 13,
  ),
),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
Widget _statCard({
  required IconData icon,
  required String title,
  required String value,
  required Color color,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    ),
  );
}

 @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFFF4F7F6),
    appBar: AppBar(
      title: const Text('FG Santé'),
      centerTitle: true,
      
      flexibleSpace: Container(
  decoration: const BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Color(0xFF0F9D58),
        Color(0xFF34A853),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ),
),
backgroundColor: Colors.transparent,
foregroundColor: Colors.white,
elevation: 0,
    ),
    body: isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
   : SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
        children: [
          Container(
  margin: const EdgeInsets.only(bottom: 24),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    gradient: const LinearGradient(
      colors: [
        Color(0xFF0F9D58),
        Color(0xFF34A853),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    color: Colors.white,
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.05),
    blurRadius: 12,
    offset: const Offset(0, 6),
  ),
],
  ),
  child: Row(
    children: [
      CircleAvatar(
        radius: 32,
        backgroundColor: Colors.white.withOpacity(0.2),
        child: const Icon(
          Icons.person,
          color: Colors.white,
          size: 34,
        ),
      ),

      const SizedBox(width: 18),

       Expanded(
        child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
   Text(
      'Bienvenue $userName',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    const Text(
      'Espace santé intelligent FG Santé',
      style: TextStyle(color: Colors.white70),
    ),
  ],
),
      ),

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.notifications_none,
          color: Colors.white,
          size: 28,
        ),
      ),
      const SizedBox(width: 8),

IconButton(
  tooltip: 'Déconnexion',
  onPressed: () async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  },
  icon: const Icon(
    Icons.logout,
    color: Colors.white,
    size: 28,
  ),
),
    ],
  ),
          ),
         Container(
  margin: const EdgeInsets.only(bottom: 24),
  child: Row(
    children: [
      
      Expanded(
        child: _statCard(
          icon: Icons.people,
          title: 'Médecins',
          value: doctorsCount.toString(),
          color: Colors.blue,
        ),
      ),

      const SizedBox(width: 12),

      Expanded(
        child: _statCard(
          icon: Icons.science,
          title: 'Résultats',
          value: resultsCount.toString(),
          color: Colors.purple,
        ),
      ),

    ],
  ),
),

Container(
  margin: const EdgeInsets.only(bottom: 24),
  child: Row(
    children: [

      Expanded(
        child: _statCard(
          icon: Icons.calendar_month,
          title: 'Rendez-vous',
          value: appointmentsCount.toString(),
          color: Colors.orange,
        ),
      ),

      const SizedBox(width: 12),

       Expanded(
        child: _statCard(
          icon: Icons.description,
          title: 'Ordonnances',
          value: prescriptionsCount.toString(),
          color: Colors.green,
        ),
      ),

    ],
  ),
), 
  Wrap(
    spacing: 16,
    runSpacing: 16,
    children: [
  if (role == 'patient') 

         _healthCard(
    
  icon: Icons.person,
  title: 'Profil médical',
  subtitle: 'Informations médicales patient',
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const PatientProfilePage(),
    ),
  );
}, 
),
 if (role == 'patient') 
    _healthCard(
      
      icon: Icons.person,
      title: 'Espace Patient',
      subtitle: 'Mes résultats, prescriptions et rendez-vous',
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const HealthPatientPage(),
    ),
  );
      },
    ),

 if (role == 'patient') 
   _healthCard(
  icon: Icons.send,
  title: 'Mes références',
  subtitle: 'Références médicales',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientReferralsPage(),
      ),
    );
  },
),
   
  

  if (role == 'doctor') 
    _healthCard(
      
      icon: Icons.medical_services,
      title: 'Dashboard médecin',
      subtitle: 'Gestion médicale',
              onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DoctorDashboardPage(),
    ),
  );
},  
    ),
    if (role == 'doctor') 
    _healthCard(
      
      icon: Icons.calendar_month,
      title: 'Mes rendez-vous',
      subtitle: 'Voir mes consultations',
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
    builder: (_) => const MyAppointmentsPage(),
    ),
  );
}, 
    ),   

if (role == "doctor")
  _healthCard(
    icon: Icons.verified_user,
    title: "Profil professionnel",
    subtitle: "Statut, spécialité et vérification",
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfessionalProfilePage(),
        ),
      );
    },
  ),

if (role == "doctor")
  _healthCard(
    icon: Icons.workspace_premium,
    title: 'Mon abonnement FG Santé',
    subtitle: 'Mensuel, trimestriel ou annuel',
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FgSanteSubscriptionPage(),
        ),
      );
    },
  ),

  

  if (role == 'admin') 
    _healthCard(
      
      icon: Icons.admin_panel_settings,
      title: 'Admin Santé',
      subtitle: 'Validation et contrôle FG Santé',
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminMedicalDocumentsPage(),
    ),
  );
}, 
    ),
    if (role == 'admin')
  _healthCard(
    icon: Icons.notifications,
    title: 'Notifications',
    subtitle: 'Demandes et réponses rendez-vous',
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DoctorAppointmentsPage(),
        ),
      );
    },
  ),
    if (role == 'admin') 
    _healthCard(
      
      icon: Icons.verified_user,
      title: 'Validation professionnels',
      subtitle: 'Approuver ou rejeter les profils santé',
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ValidationProfessionalsPage(),
    ),
  );
}, 
    ),
    if (role == 'admin') 
    _healthCard(
      
      icon: Icons.medication,
      title: 'Prescriptions Admin',
      subtitle: 'Suivi des ordonnances',
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminPrescriptionsPage(),
    ),
  );
}, 
    ),
    if (role == 'admin') 
    _healthCard(
      
      icon: Icons.science,
      title: 'Résultats Admin',
      subtitle: 'Résultats médicaux patients',
      onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const MedicalResultsPage(isAdmin: true),
    ),
  );
}, 
    ), 
  
    ],
  ),
        ],
  ),
   ),  
  );
}
}
