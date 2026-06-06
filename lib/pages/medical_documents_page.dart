import 'package:flutter/material.dart';
import 'prescriptions_page.dart';
import 'admin_prescriptions_page.dart';
import 'admin_medical_records_page.dart';
import 'add_medical_record_page.dart';
import 'patient_references_page.dart';



class MedicalDocumentsPage extends StatelessWidget {
  final int patientId;

  const MedicalDocumentsPage({
    super.key,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents médicaux'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

         

          Card(
  child: ListTile(
    leading: const Icon(
      Icons.medication,
      color: Colors.green,
    ),
    title: const Text('Ordonnances'),
    subtitle: const Text(
      'Prescriptions médicales',
    ),
    trailing: const Icon(Icons.arrow_forward_ios),
   onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminPrescriptionsPage(),
    ),
  );
},
  ),
),



          Card(
            child:ListTile(
  leading: const Icon(
    Icons.assignment_outlined,
    color: Colors.orange,
  ),
  title: const Text('Références'),
  subtitle: const Text(
    'Transferts et références',
  ),
  trailing: const Icon(Icons.chevron_right),

  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PatientReferencesPage(),
      ),
    );
  },
), 
          ),

Card(
  child: ListTile(
    leading: const Icon(
      Icons.description,
      color: Colors.blue,
    ),
    title: const Text('Résultats médicaux'),
    subtitle: const Text(
      'Résultats laboratoire et examens',
    ),
    trailing: const Icon(Icons.arrow_forward_ios),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminMedicalRecordsPage(),
        ),
      );
    },
  ),
),

          Card(
  child: ListTile(
    leading: const Icon(
      Icons.attach_file,
      color: Colors.purple,
    ),
    title: const Text('Pièces justificatives'),
    subtitle: const Text('Documents complémentaires'),
    trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const AdminMedicalRecordsPage(),
        
      
    ),
  );
},
  ),
),
        ],
      ),
    );
  }
}