import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalRecordDetailsPage extends StatelessWidget {
  final dynamic record;

  const MedicalRecordDetailsPage({
    super.key,
    required this.record,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          record['title'] ?? 'Détails',
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: ListView(
          children: [

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.science,
                  color: Colors.green,
                ),

                title: Text(
                  record['title'] ?? '-',
                ),

                subtitle: Text(
                  record['type'] ?? '-',
                ),
              ),
            ),

            const SizedBox(height:16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    const Text(
                      'Description',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height:8),

                    Text(
                      record['description'] ?? '-',
                    ),

                    const SizedBox(height:20),

                    Text(
                      "Médecin : ${record['doctor_name'] ?? '-'}",
                    ),

                    Text(
                      "Clinique : ${record['clinic_name'] ?? '-'}",
                    ),

                    Text(
                      "Date : ${record['created_at'] ?? '-'}",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height:20),

            if (record['file_url'] != null &&
    record['file_url'].toString().isNotEmpty)
  ElevatedButton.icon(
    onPressed: () async {
     final fileUrl = record['file_url'];

final fullUrl = fileUrl.toString().startsWith('http')
    ? fileUrl
    : 'http://localhost:3000$fileUrl';

      await launchUrl(
  Uri.parse(fullUrl),
  mode: LaunchMode.externalApplication,
);
    },
    icon: const Icon(Icons.visibility),
    label: const Text('Voir document'),
  ),
          ],
        ),
      ),
    );
  }
}