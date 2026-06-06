import 'package:flutter/material.dart';
import '../services/prescription_service.dart';
import '../services/pdf_service.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientPrescriptionsPage extends StatefulWidget {
  final int patientId;

  const PatientPrescriptionsPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientPrescriptionsPage> createState() =>
      _PatientPrescriptionsPageState();
}

class _PatientPrescriptionsPageState
    extends State<PatientPrescriptionsPage> {

  List prescriptions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPrescriptions();
  }

 Future<void> loadPrescriptions() async {
  try {
    final data =
        await PrescriptionService().getMyPrescriptions();

    setState(() {
      prescriptions = data;
      isLoading = false;
    });
  } catch (e) {
    print(e);

    setState(() {
      isLoading = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text('Mes prescriptions'),
        backgroundColor: Colors.green,
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : prescriptions.isEmpty
              ? const Center(
                  child: Text('Aucune prescription'),
                )

              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: prescriptions.length,

                  itemBuilder: (context, index) {

                    final prescription =
                        prescriptions[index];

                       final medicationName =
    (prescription['medication'] ??
     prescription['medications'] ??
     'Médicament non renseigné')
    .toString()
    .trim();
    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),

                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [

                        Text(
  '${prescription['medication'] ?? prescription['medications'] ?? ''}',
  style: const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),


                          const SizedBox(height: 10),

                          Text(
                            'Dosage: ${prescription['dosage'] ?? ''}',
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Durée: ${prescription['duration'] ?? ''}',
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Notes: ${prescription['notes'] ?? ''}',
                          ),
const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  child: ElevatedButton.icon(
    onPressed: () async {
  await PdfService.generatePrescriptionPdf(
    patientName: prescription['patient_name'] ?? '',
    doctorName: prescription['doctor_name'] ?? '',
    medication: prescription['medication'] ?? '',
    dosage: prescription['dosage'] ?? '',
    duration: prescription['duration'] ?? '',
    notes: prescription['notes'] ?? '',
  );

     

    },
    icon: const Icon(Icons.picture_as_pdf),
    label: const Text('Télécharger PDF'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
    ),
  ),
),
                          const SizedBox(height: 10),

                          Text(
                            'Médecin: ${prescription['doctor_name'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}