import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AppointmentService {
  static const String baseUrl = 'http://localhost:3000/api';

  static Future<Map<String, dynamic>> createAppointment({
  required int patientId,
  required int doctorId,
  required String date,
  required String time,
  required String reason,
  int? referralId,
}) async {
  final token = await AuthService.getToken();

  final  body = {
    'patient_id': patientId,
    'doctor_id': doctorId,
    'date': date,
    'time': time,
    'reason': reason,
  };

  if (referralId != null) {
    body['referral_id'] = referralId;
  }
try {
  print('BODY RDV: $body');

  final response = await http.post(
    Uri.parse('$baseUrl/appointments'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(body),
  );

  print('STATUS RDV: ${response.statusCode}');
  print('BODY RDV: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(data['message'] ?? data['error'] ?? 'Erreur création rendez-vous');
  }

  return data;
} catch (e) {
  print('RDV EXCEPTION: $e');
  rethrow;
}
}

  static Future<List<dynamic>> getPatientAppointments() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('$baseUrl/appointments/patient'),
    headers: {'Authorization': 'Bearer $token'},
  );

  print('STATUS: ${response.statusCode}');
  print('BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return [];
  }

  final data = jsonDecode(response.body);
  return data['appointments'] ?? [];
}

static Future<bool> completeAppointment(int appointmentId) async {
  final token = await AuthService.getToken();

  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/api/appointments/$appointmentId/complete'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  return response.statusCode == 200;
}

  static Future<List<dynamic>> getDoctorAppointments() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('$baseUrl/appointments/doctor'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  print('STATUS: ${response.statusCode}');
  print('BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return [];
  }

  final data = jsonDecode(response.body);
  return data['appointments'] ?? [];
}

static Future<Map<String, dynamic>?> getNextAppointment() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/appointments/doctor/next'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('NEXT URL = ${ApiConfig.baseUrl}/api/appointments/doctor/next');
  print('NEXT STATUS = ${response.statusCode}');
  print('NEXT BODY = ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data['appointment'];
  }

  return null;
}


static Future<Map<String, dynamic>> acceptAppointment({

  required int appointmentId,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/appointments/$appointmentId/accept'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('ACCEPT STATUS: ${response.statusCode}');
  print('ACCEPT BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return {};
  }

  return jsonDecode(response.body);
}

static Future<List<dynamic>> getAdminAppointments() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/appointments/admin/all'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data['appointments'] ?? [];
  }

  return [];
}

static Future<Map<String, dynamic>> updateAppointmentStatus({
  required int appointmentId,
  required String status,
}) async {
  final token = await AuthService.getToken();

  final url = Uri.parse(
  '${ApiConfig.baseUrl}/api/appointments/$appointmentId/status',
);

print('UPDATE APPOINTMENT URL: $url');

final response = await http.put(
  url,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'status': status,
  }),
);

  print('UPDATE STATUS: ${response.statusCode}');
  print('UPDATE BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return {};
  }

  return jsonDecode(response.body);
}

static Future<List<dynamic>> getNotifications() async {

  final token = await AuthService.getToken();
print('NOTIF URL: $baseUrl/notifications');
  final response = await http.get(
    Uri.parse('$baseUrl/notifications'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  print('NOTIF STATUS: ${response.statusCode}');
  print('NOTIF BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return [];
  }

  final data = jsonDecode(response.body);
  return data['notifications'] ?? [];
}
  
}