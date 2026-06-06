import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import 'appointment_details_page.dart';
import 'doctor_prescription_page.dart';
import 'create_medical_record_page.dart';


class DoctorAppointmentsPage extends StatefulWidget {
  final int? patientId;

const DoctorAppointmentsPage({
  super.key,
  this.patientId,
});


  @override
  State<DoctorAppointmentsPage> createState() =>
      _DoctorAppointmentsPageState();
}

class _DoctorAppointmentsPageState
    extends State<DoctorAppointmentsPage> {
  bool isLoading = true;
  List appointments = [];

  @override
  void initState() {
    super.initState();
    loadAppointments();
  }

  Future<void> loadAppointments() async {
  final result = await AppointmentService.getDoctorAppointments();

  appointments = result;

  if (widget.patientId != null) {
    appointments = appointments
        .where((a) => a['patient_id'] == widget.patientId)
        .toList();
  }

  setState(() {
    isLoading = false;
  });
}


 Future<void> updateStatus(
    int appointmentId,
    String status,
) async {
  try {
   if (status == 'accepted') {
  await AppointmentService.acceptAppointment(
    appointmentId: appointmentId,
  );
} else {
  await AppointmentService.updateAppointmentStatus(
    appointmentId: appointmentId,
    status: status,
  );
}

    // Rechaje lis la
    await loadAppointments();

    if (mounted) {
      setState(() {});
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Randevou $status avèk siksè',
        ),
      ),
    );
  } catch (e) {
    print(e);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erreur: $e',
        ),
      ),
    );
  }
}

  Widget buildCard(dynamic appointment) {
    final status = (
  appointment['appointment_status'] ??
  appointment['status'] ??
  'pending'
).toString();

    return GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AppointmentDetailsPage(
          appointment: appointment,
        ),
      ),
    );
  },

  child: Container(
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
            const Icon(
              Icons.person,
              color: Colors.blue,
            ),
        
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    appointment['patient_name'] ?? 'Patient',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    appointment['appointment_date']
                        .toString()
                        .split('T')[0],
                  ),
                  Text(
                    appointment['appointment_time'] ?? '',
                  ),
                  Text(
                    appointment['reason'] ?? '',
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Text(
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
                if (status == 'pending') ...[
                  const SizedBox(height: 8),
                Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Text(
      status.toUpperCase(),
      style: const TextStyle(
        color: Colors.orange,
        fontWeight: FontWeight.bold,
      ),
    ),

    const SizedBox(height: 10),

    SizedBox(
      width: 120,
      height: 42,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
       onPressed: () {
  updateStatus(
    appointment['appointment_id'] ?? appointment['id'],
    'accepted',
  );
},
        icon: const Icon(Icons.check, size: 18),
        label: const Text('ACCEPTER'),
      ),
    ),

const SizedBox(height: 10),

SizedBox(
  width: 120,
  height: 42,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    onPressed: () {
  print('APPOINTMENT DATA: $appointment');
  print('PATIENT ID: ${appointment['patient_id']}');
  print('PATIENT NAME: ${appointment['patient_name']}');
  print('PATIENT PHONE: ${appointment['patient_phone']}');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => DoctorPrescriptionPage(
       appointment: {
  'appointment_id': appointment['appointment_id'] ?? appointment['id'],
  'patient_id': appointment['patient_id'],
  'patient_name': appointment['patient_name'],
  'patient_phone': appointment['patient_phone'] ?? appointment['phone'],
},
      ),
    ),
  );
},
    icon: const Icon(Icons.receipt_long, size: 18),
    label: const Text('ORDONNANCE'),
  ),
),

    const SizedBox(height: 8),

    SizedBox(
      width: 120,
      height: 42,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
       onPressed: () {
  updateStatus(
    appointment['appointment_id'] ?? appointment['id'],
    'rejected',
  );
},


        icon: const Icon(Icons.close, size: 18),
        label: const Text('REJETER'),
      ),
    ),
  ],
),

SizedBox(
  width: 170,
  height: 42,
  child: ElevatedButton.icon(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    onPressed: () {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateMedicalRecordPage(
            appointment: appointment,
          ),
        ),
      );

    },
    icon: const Icon(
      Icons.folder_copy,
      size: 18,
    ),
    label: const Text(
      'DOSYE MEDIKAL',
    ),
  ),
),

                ],
            
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Rendez-vous patients'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : appointments.isEmpty
              ? const Center(child: Text('Aucun rendez-vous'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                 itemBuilder: (context, index) {
  final appointment = appointments[index];

  return InkWell(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AppointmentDetailsPage(
            appointment: appointment,
          ),
        ),
      );
    },
    child: buildCard(appointment),
  );
},
                ),
    );
  }
}