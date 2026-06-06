import 'package:flutter/material.dart';
import '../services/appointment_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SecretaryCreateAppointmentPage extends StatefulWidget {
  final Map<String, dynamic>? referral;

  const SecretaryCreateAppointmentPage({
    super.key,
    this.referral,
  });


  @override
  State<SecretaryCreateAppointmentPage> createState() =>
      _SecretaryCreateAppointmentPageState();
}
List patients = [];
List doctors = [];

class _SecretaryCreateAppointmentPageState
    extends State<SecretaryCreateAppointmentPage> {
  int? selectedPatientId;
  int? selectedDoctorId;
  DateTime? selectedDate;
  String? selectedTime;
  

  final reasonController = TextEditingController();

@override
void initState() {
  super.initState();
loadPatientsAndDoctors();
 final referral = widget.referral;

selectedPatientId = referral?['patient_id'];
selectedDoctorId = referral?['doctor_id'];

reasonController.text = referral?['reason']?.toString() ?? '';
  

  print('SECRETARY REFERRAL: ${widget.referral}');
  print('SECRETARY REFERRAL ID: ${widget.referral?['id']}');
  
}

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

Future<void> loadPatientsAndDoctors() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final patientsResponse = await http.get(
    Uri.parse('https://fgpay-backend-production.up.railway.app/api/appointments/patients'),
    headers: {'Authorization': 'Bearer $token'},
  );

  final doctorsResponse = await http.get(
    Uri.parse('https://fgpay-backend-production.up.railway.app/api/appointments/doctors-list'),
    headers: {'Authorization': 'Bearer $token'},
  );

  final patientsData = jsonDecode(patientsResponse.body);
final doctorsData = jsonDecode(doctorsResponse.body);

print('PATIENTS RESPONSE = ${patientsResponse.body}');
print('DOCTORS RESPONSE = ${doctorsResponse.body}');
print('DOCTORS STATUS = ${doctorsResponse.statusCode}');

setState(() {
  patients = patientsData['patients'] ?? [];
  doctors = doctorsData['doctors'] ?? [];
});

print('DOCTORS LIST = $doctors');
}


  Future<void> _createAppointment() async {
  if (selectedPatientId == null ||
      selectedDoctorId == null ||
      selectedDate == null ||
      selectedTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tanpri ranpli tout chan yo')),
    );
    return;
  }

if (selectedPatientId == null || selectedDoctorId == null || selectedDate == null || selectedTime == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Tanpri ranpli tout chan yo')),
  );
  return;
}

  try {
  final result = await AppointmentService.createAppointment(
  patientId: selectedPatientId!,
  doctorId: selectedDoctorId!,
  date: _formatDate(selectedDate!),
  time: selectedTime!,
  reason: reasonController.text.trim(),
  referralId: widget.referral?['id'],
);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Randevou kreye avèk siksè')),
    );

    Navigator.pop(context, true);
  } catch (e) {
     print('CREATE APPOINTMENT ERROR = $e');
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erè: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    final uniquePatients = {
  for (var p in patients) p['id']: p
}.values.toList();

final uniqueDoctors = {
  for (var d in doctors) d['id']: d
}.values.toList();

if (selectedPatientId != null &&
    !uniquePatients.any((p) => p['id'] == selectedPatientId)) {
  selectedPatientId = null;
}

if (selectedDoctorId != null &&
    !uniqueDoctors.any((d) => d['id'] == selectedDoctorId)) {
  selectedDoctorId = null;
}
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer rendez-vous'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
          DropdownButtonFormField<int>(
  decoration: const InputDecoration(
    labelText: 'Patient',
    border: OutlineInputBorder(),
  ),
  value: selectedPatientId,
  items: patients.map<DropdownMenuItem<int>>((p) {
    return DropdownMenuItem<int>(
      value: p['id'],
      child: Text('${p['full_name'] ?? p['name']} - ${p['phone']}'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedPatientId = value;
    });
  },
          ),
            
const SizedBox(height: 15),

          DropdownButtonFormField<int>(
  decoration: const InputDecoration(
    labelText: 'Médecin',
    border: OutlineInputBorder(),
  ),
  value: selectedDoctorId,
  items: doctors.map<DropdownMenuItem<int>>((d) {
    return DropdownMenuItem<int>(
      value: d['id'],
      child: Text('${d['full_name'] ?? d['name']} - ${d['phone']}'),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedDoctorId = value;
    });
  },
),
          
            const SizedBox(height: 15),



            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Motif',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  initialDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                selectedDate == null ? 'Choisir date' : _formatDate(selectedDate!),
              ),
            ),
            const SizedBox(height: 15),

            OutlinedButton.icon(
              onPressed: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );

                if (time != null) {
                  setState(() {
                    selectedTime = time.format(context);
                  });
                }
              },
              icon: const Icon(Icons.access_time),
              label: Text(
                selectedTime == null ? 'Choisir heure' : selectedTime!,
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _createAppointment,
                icon: const Icon(Icons.save),
                label: const Text('Créer rendez-vous'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}