import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

class MedicalRecordDetailPage extends StatelessWidget {
  final Map<String, dynamic> record;

  const MedicalRecordDetailPage({
    super.key,
    required this.record,
  });

String formatDate(dynamic value) {
  if (value == null) return 'Non renseignée';

  final date = DateTime.parse(value.toString()).toLocal();

  return '${date.day.toString().padLeft(2,'0')}/'
      '${date.month.toString().padLeft(2,'0')}/'
      '${date.year} '
      '${date.hour.toString().padLeft(2,'0')}:'
      '${date.minute.toString().padLeft(2,'0')}';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail résultat médical'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record['title'] ?? 'Résultat médical',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 20),

            _card(
              title: 'Catégorie',
              value: record['type'] ??
                  record['category'] ??
                  '',
            ),

            const SizedBox(height: 12),

            _card(
              title: 'Description',
              value: record['description'] ??
                  record['notes'] ??
                  '',
            ),

            const SizedBox(height: 12),

            _card(
              title: 'Médecin',
              value: record['doctor_name'] ??
                  'Non renseigné',
            ),

            const SizedBox(height: 12),

            _card(
  title: 'Clinique',
  value: record['clinic_name'] ??
      'Non renseignée',
),

const SizedBox(height: 12),

_card(
  title: 'Date',
  value: formatDate(record['created_at']),
),

const SizedBox(height: 30),


// QR ICI
if (record['verification_code'] != null)
  Column(
    children: [
      QrImageView(
        data:
            'http://localhost:3000/api/medical-records/verify/${record['verification_code']}',
        size: 120,
      ),

      const SizedBox(height: 8),

      Text(
        'Code vérification: ${record['verification_code']}',
      ),
    ],
  ),

const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
               onPressed: () async {

  if (record['file_url'] == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Aucun fichier disponible'),
      ),
    );
    return;
  }

  final fileUrl =
      'http://localhost:3000${record['file_url']}';

  html.window.open(fileUrl, '_blank');
},
               label: const Text(
  'Télécharger résultat',
),

style: ElevatedButton.styleFrom(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(
    vertical: 16,
  ),
),

),
),

const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  child: OutlinedButton.icon(
    onPressed: () async {

      if (record['file_url'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun fichier disponible'),
          ),
        );
        return;
      }

      final fileUrl =
          'http://localhost:3000${record['file_url']}';

      html.window.open(fileUrl, '_blank');
    },

    icon: const Icon(Icons.visibility),

    label: const Text(
      'Voir / ouvrir le fichier',
    ),

  style: ElevatedButton.styleFrom(
  backgroundColor: Colors.green,
  foregroundColor: Colors.white,
  padding: const EdgeInsets.symmetric(
    vertical: 16,
  ),
  ),
  
  ),
),
  const SizedBox(height: 12),

              
            
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value.isEmpty
                ? 'Non renseigné'
                : value,
          ),
        ],
      ),
    );
  }
}