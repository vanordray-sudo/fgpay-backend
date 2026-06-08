import 'package:flutter/material.dart';
import '../services/health_service.dart';

class PatientMedicalCompletePage extends StatefulWidget {
  final int patientId;

  const PatientMedicalCompletePage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientMedicalCompletePage> createState() =>
      _PatientMedicalCompletePageState();
}

class _PatientMedicalCompletePageState
    extends State<PatientMedicalCompletePage> {
  bool isLoading = true;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadMedicalFile();
  }

  Future<void> loadMedicalFile() async {
    try {
      final result =
          await HealthService.getFullMedicalFile(widget.patientId);

      setState(() {
        data = result;
        isLoading = false;
      });
    } catch (e) {
      print('DOSSIER MEDICAL ERROR: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.grey),
      ),
    );
  }

  Widget simpleCard({
    required String title,
    required String subtitle,
    String? extra,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(extra == null ? subtitle : '$subtitle\n$extra'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final patient = data?['patient'];
    final appointments = data?['appointments'] ?? [];
    final prescriptions = data?['prescriptions'] ?? [];
    final records = data?['records'] ?? [];
    final referrals = data?['referrals'] ?? [];

print('FLUTTER RECORDS = $records');
print('FLUTTER RECORDS LENGTH = ${records.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dossier Médical'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(
                  child: Text('Impossible de charger le dossier médical'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        color: Colors.green.shade50,
                        child: ListTile(
                          leading: const Icon(
                            Icons.folder_shared,
                            color: Colors.green,
                            size: 38,
                          ),
                          title: Text(
                            patient?['full_name'] ?? 'Patient',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          subtitle: Text(
                            'Téléphone : ${patient?['phone'] ?? 'Non renseigné'}\n'
                            'Email : ${patient?['email'] ?? 'Non renseigné'}',
                          ),
                        ),
                      ),

                      sectionTitle('Historique RDV', Icons.calendar_month),
                      appointments.isEmpty
                          ? emptyText('Aucun rendez-vous trouvé')
                          : Column(
                              children: appointments.map<Widget>((rdv) {
                                return simpleCard(
                                  title: rdv['reason'] ?? 'Rendez-vous',
                                  subtitle:
                                      'Date : ${rdv['appointment_date'] ?? ''}',
                                  extra:
                                      'Heure : ${rdv['appointment_time'] ?? ''}\nStatut : ${rdv['status'] ?? ''}',
                                );
                              }).toList(),
                            ),

                      sectionTitle('Prescriptions', Icons.receipt_long),
                      prescriptions.isEmpty
                          ? emptyText('Aucune prescription trouvée')
                          : Column(
                              children: prescriptions.map<Widget>((p) {
                                return simpleCard(
                                  title: p['medication'] ??
                                      p['title'] ??
                                      'Prescription',
                                  subtitle:
                                      'Dosage : ${p['dosage'] ?? 'Non renseigné'}',
                                  extra:
                                      'Durée : ${p['duration'] ?? 'Non renseignée'}\nDate : ${p['created_at'] ?? ''}',
                                );
                              }).toList(),
                            ),

                      sectionTitle('Résultats labo', Icons.science),
                      records.isEmpty
                          ? emptyText('Aucun résultat trouvé')
                          : Column(
                              children: records.map<Widget>((r) {
                                return simpleCard(
                                  title: r['title'] ?? 'Résultat médical',
                                  subtitle:
                                      'Type : ${r['category'] ?? r['type'] ?? ''}',
                                  extra:
                                      'Médecin : ${r['doctor_name'] ?? ''}\nDate : ${r['created_at'] ?? ''}',
                                );
                              }).toList(),
                            ),

                      sectionTitle('Références', Icons.send),
                      referrals.isEmpty
                          ? emptyText('Aucune référence trouvée')
                          : Column(
                              children: referrals.map<Widget>((ref) {
                                return simpleCard(
                                  title: ref['reason'] ?? 'Référence médicale',
                                  subtitle:
                                      'Priorité : ${ref['priority'] ?? 'Normale'}',
                                  extra:
                                      'Spécialité : ${ref['to_specialty_id'] ?? ''}\nDate : ${ref['created_at'] ?? ''}',
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
    );
  }
}