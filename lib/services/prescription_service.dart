import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PrescriptionService {
 static const String baseUrl = 'http://localhost:3000/api';

 static Future<Map<String, dynamic>> createPrescription({
  required String? patientName,
  required String? patientPhone,
           String? patientBirthDate,
           String? appointmentDate,
           String? appointmentTime,
  required int? patientId,
  required int? appointmentId,
  required String medication,
  required String dosage,
  required String duration,
  required String instructions,
  required String doctorName,
  required String clinicName,
  required String prescriptionDate,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/prescriptions/create'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },



    body: jsonEncode({
  'patient_name': patientName,
  'patient_phone': patientPhone,
  'patient_birth_date': patientBirthDate,
  'appointment_time': appointmentTime,
  'appointment_date': appointmentDate,
  'patient_id': patientId,
  'appointment_id': appointmentId,
  'medication': medication,
  'dosage': dosage,
  'duration': duration,
  'instructions': instructions,
  'doctor_name': doctorName,
  'clinic_name': clinicName,
  'prescription_date': prescriptionDate,
    }),
  );


print('CREATE PRESCRIPTION STATUS: ${response.statusCode}');
print('CREATE PRESCRIPTION BODY: ${response.body}');
  
    return jsonDecode(response.body);
  

  
}
Future<List<dynamic>> getMyPrescriptions() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/prescriptions/patient'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('PRESCRIPTIONS BODY: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['prescriptions'] ?? [];
  }

  return [];
}

static Future<List<dynamic>> getDoctorPrescriptions() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('$baseUrl/prescriptions/doctor'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('DOCTOR PRESCRIPTIONS STATUS: ${response.statusCode}');
  print('DOCTOR PRESCRIPTIONS BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return [];
  }

  final data = jsonDecode(response.body);
  return data['prescriptions'] ?? [];
}

}

