import 'package:flutter/material.dart';
import 'admin_professionals_page.dart';
import 'package:fgpay_clean/pages/admin_professionals_page.dart';
import 'medical_documents_page.dart';


class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Administration FG Santé',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Gérer les validations, les professionnels et la sécurité.',
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 24),

            _adminCard(
              context,
              title: 'Professionnels Santé',
              subtitle: 'Valider ou rejeter médecins, cliniques et laboratoires',
              icon: Icons.verified_user,
              color: Colors.green,
              page: const AdminProfessionalsPage(),
            ),

            const SizedBox(height: 14),

            _adminCard(
              context,
              title: 'Patients',
              subtitle: 'Voir et gérer les comptes patients',
              icon: Icons.people,
              color: Colors.blue,
              page: const PlaceholderPage(title: 'Patients'),
            ),

            const SizedBox(height: 14),

            _adminCard(
              context,
              title: 'Rendez-vous',
              subtitle: 'Suivi des rendez-vous médicaux',
              icon: Icons.calendar_month,
              color: Colors.orange,
              page: const PlaceholderPage(title: 'Rendez-vous'),
            ),

const SizedBox(height: 14),



            const SizedBox(height: 14),

            _adminCard(
              context,
              title: 'Documents médicaux',
              subtitle: 'Contrôle des pièces et justificatifs',
              icon: Icons.folder_copy,
              color: Colors.purple,
              page: MedicalDocumentsPage(
  patientId: 4,
),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
  }) {
    return InkWell(
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [

          const SizedBox(height: 14),

            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String title;

  const PlaceholderPage({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('$title bientôt disponible'),
      ),
    );
  }
}