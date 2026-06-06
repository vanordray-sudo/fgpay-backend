import 'package:flutter/material.dart';
import 'doctor_prescription_page.dart';
import 'create_medical_record_page.dart';
import 'patient_referrals_page.dart';


class AppointmentDetailsPage extends StatelessWidget {
  final Map appointment;

  const AppointmentDetailsPage({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    final status =
        appointment['status'] ?? 'pending';

    Color statusColor;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        break;

      case 'rejected':
        statusColor = Colors.red;
        break;

      default:
        statusColor = Colors.orange;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Détails rendez-vous',
        ),
        backgroundColor: Colors.blue,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          children: [

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  Row(
                    children: [

                      CircleAvatar(
                        radius: 30,
                        backgroundColor:
                            Colors.blue.withOpacity(0.15),

                        child: const Icon(
                          Icons.person,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),

                      const SizedBox(width: 15),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              appointment['patient_name']
                                      ?.toString() ??
                                  'Patient',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),

                              decoration: BoxDecoration(
                                color: statusColor
                                    .withOpacity(0.12),

                                borderRadius:
                                    BorderRadius.circular(20),
                              ),

                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _buildInfoTile(
                    icon: Icons.calendar_month,
                    title: 'Date',
                    value: appointment[
                            'appointment_date']
                        .toString()
                        .split('T')[0],
                  ),

                  const SizedBox(height: 16),

                  _buildInfoTile(
                    icon: Icons.access_time,
                    title: 'Heure',
                    value: appointment[
                            'appointment_time'] ??
                        '',
                  ),

                  const SizedBox(height: 16),

                  _buildInfoTile(
                    icon: Icons.notes,
                    title: 'Motif',
                    value:
                        appointment['reason'] ??
                            'Non spécifié',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorPrescriptionPage(
          appointment: appointment,
        ),
      ),
    );
  },
  child: _buildActionButton(
    title: 'Créer prescription',
    icon: Icons.receipt_long,
    color: Colors.green,
  ),
),

            const SizedBox(height: 14),

           GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateMedicalRecordPage(
          
        ),
      ),
    );
  },
  child: _buildActionButton(
    title: 'Ajouter résultat',
    icon: Icons.science,
    color: Colors.orange,
  ),
),

            const SizedBox(height: 14),

 GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>  CreateMedicalRecordPage(),
      ),
    );
  },
  child: _buildActionButton(
    title: 'Faire référence',
    icon: Icons.forward,
    color: Colors.blue,
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [

        CircleAvatar(
          radius: 22,
          backgroundColor:
              Colors.blue.withOpacity(0.1),

          child: Icon(
            icon,
            color: Colors.blue,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Row(
        children: [

          CircleAvatar(
            backgroundColor:
                color.withOpacity(0.15),

            child: Icon(
              icon,
              color: color,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 18,
          ),
        ],
      ),
    );
  }
}