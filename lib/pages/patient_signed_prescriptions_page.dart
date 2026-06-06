import 'package:flutter/material.dart';
import '../services/health_service.dart';
import '../services/pdf_service.dart';

class PatientSignedPrescriptionsPage extends StatefulWidget {
  final int patientId;

  const PatientSignedPrescriptionsPage({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientSignedPrescriptionsPage> createState() =>
      _PatientSignedPrescriptionsPageState();
}

class _PatientSignedPrescriptionsPageState
    extends State<PatientSignedPrescriptionsPage> {

  bool loading = true;

  List prescriptions = [];

  @override
  void initState() {
    super.initState();
    loadPrescriptions();
  }

  Future<void> loadPrescriptions() async {
    try {

     final data =
    await HealthService.getPrescriptions();
    
      setState(() {
        prescriptions = data;
        loading = false;
      });

    } catch (e) {

      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text(
          'Ordonnances signées',
        ),
        backgroundColor: Colors.green,
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )

          : prescriptions.isEmpty

              ? const Center(
                  child: Text(
                    'Aucune ordonnance',
                  ),
                )

              : ListView.builder(

                  padding:
                      const EdgeInsets.all(16),

                  itemCount:
                      prescriptions.length,

                  itemBuilder:
                      (context, index) {

                    final prescription =
                        prescriptions[index];

                    return Card(

                      margin:
                          const EdgeInsets.only(
                        bottom: 14,
                      ),

                      child: Padding(

                        padding:
                            const EdgeInsets.all(
                          16,
                        ),

                        child: Column(

                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [

                            Text(
                              prescription[
                                      'medication'] ??
                                  '',
                              style:
                                  const TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 8,
                            ),

                            Text(
                              "Médecin: ${prescription['doctor_name'] ?? '-'}",
                              style:
                                  const TextStyle(
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            SizedBox(
                              width:
                                  double.infinity,

                              child:
                                  ElevatedButton.icon(

                                onPressed:
                                    () async {

                                  await PdfService
                                      .generatePrescriptionPdf(
                                    patientName:
                                        prescription[
                                                'patient_name'] ??
                                            '',
                                    doctorName:
                                        prescription[
                                                'doctor_name'] ??
                                            '',
                                    medication:
                                        prescription[
                                                'medication'] ??
                                            '',
                                    dosage:
                                        prescription[
                                                'dosage'] ??
                                            '',
                                    duration:
                                        prescription[
                                                'duration'] ??
                                            '',
                                    notes:
                                        prescription[
                                                'notes'] ??
                                            '',
                                  );
                                },

                                icon: const Icon(
                                  Icons.picture_as_pdf,
                                ),

                                label: const Text(
                                  'Télécharger PDF',
                                ),

                                style:
                                    ElevatedButton
                                        .styleFrom(
                                  backgroundColor:
                                      Colors.green,
                                  foregroundColor:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}