import 'package:flutter/material.dart';

import '../services/appointment_service.dart';

class PatientAppointmentsPage
    extends StatefulWidget {
  const PatientAppointmentsPage({
    super.key,
  });

  @override
  State<PatientAppointmentsPage>
      createState() =>
          _PatientAppointmentsPageState();
}

class _PatientAppointmentsPageState
    extends State<
        PatientAppointmentsPage> {
  bool isLoading = true;

  List appointments = [];



 @override
void initState() {
  super.initState();
  loadAppointments();
}

Future<void> loadAppointments() async {
  try {
    final result = await AppointmentService.getPatientAppointments();

    if (!mounted) return;

    setState(() {
      appointments = result;
      isLoading = false;
    });
  } catch (e) {
    print('PATIENT APPOINTMENTS ERROR: $e');

    if (!mounted) return;

    setState(() {
      appointments = [];
      isLoading = false;
    });
  }
}



  Color getStatusColor(
    String status,
  ) {
    switch (status) {
      case 'accepted':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }


Widget buildCard(dynamic appointment) {
  final status = (
  appointment['appointment_status'] ??
  appointment['status'] ??
  'pending'
).toString();

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.calendar_month,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
   

  Text(
    appointment['doctor_name'] ??
    appointment['doctor_full_name'] ??
    appointment['name'] ??
    'Médecin',
    style: const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    ),
  ),

  const SizedBox(height: 6),

  Text(
    appointment['patient_name'] ?? 'Patient',
    style: TextStyle(
      color: Colors.grey.shade700,
    ),
  ),

  Text(
    appointment['phone'] ??
    appointment['patient_phone'] ??
    'Téléphone non renseigné',
    style: TextStyle(
      color: Colors.grey.shade700,
    ),
  ),

  const SizedBox(height: 6),




                const SizedBox(height: 6),
                Text(
  '${appointment['appointment_date'] ?? appointment['date'] ?? ''} '
  '${appointment['appointment_time'] ?? appointment['time'] ?? ''}',
),
                Text(
                  appointment['appointment_reason'] ?? '',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
         Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  decoration: BoxDecoration(
    color: Colors.orange.withOpacity(0.12),
    borderRadius: BorderRadius.circular(20),
  ),
  child: Text(
  status.toUpperCase(),
  style: TextStyle(
    color: status == 'accepted'
        ? Colors.green
        : status == 'rejected'
            ? Colors.red
            : Colors.orange,
    fontWeight: FontWeight.bold,
  ),
),
),
        ],
      ),
    ),
  );
}



  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text(
          'Mes rendez-vous',
        ),
        backgroundColor:
            Colors.blue,
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : appointments.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun rendez-vous',
                  ),
                )
              : RefreshIndicator(
                  onRefresh:
                      loadAppointments,
                  child:
                      ListView.builder(
                    padding:
                        const EdgeInsets
                            .all(16),
                    itemCount:
                        appointments
                            .length,
                    itemBuilder:
                        (context,
                            index) {
                      return buildCard(
                        appointments[
                            index],
                      );
                    },
                  ),
                ),
    );
  }
}