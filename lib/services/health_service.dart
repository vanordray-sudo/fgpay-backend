import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';
import 'dart:convert';
import 'package:fgpay_clean/utils/session_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';



class HealthService {



  static const String baseUrl =
      'http://localhost:3000/api/health';

static Future<Map<String, dynamic>> addPrescription({
  required String patientId,
  required String medication,
  required String dosage,
  required String instructions,
  required String duration,
  required String doctorName,
  required String clinicName,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/prescriptions/manual'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
   body: jsonEncode({
  'patientId': patientId,
  'medication': medication,
  'dosage': dosage,
  'duration': duration,
  'instructions': instructions,
  'doctorName': doctorName,
  'clinicName': clinicName,
}),
  );

  if (response.body.isEmpty) {
    return {
      'success': false,
      'message': 'Réponse serveur vide',
    };
  }

  return jsonDecode(response.body);
}
 
static Future<Map<String, dynamic>> getFullMedicalFile(int patientId) async {
  final token = await AuthService.getToken();

  final url = '$baseUrl/full-medical-file/$patientId';

  final response = await http.get(
    Uri.parse(url),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    },
  );

  print('DOSSIER URL = $url');
  print('DOSSIER STATUS = ${response.statusCode}');
  print('DOSSIER BODY = ${response.body}');

  final data = jsonDecode(response.body);

if (response.statusCode == 200 && data['success'] == true) {
  return data;
}

throw Exception(
  data['message'] ?? 'Erreur chargement dossier médical',
);
}

static Future<Map<String, dynamic>> getNextAppointment() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/appointments/doctor/next'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
print('NEXT STATUS = ${response.statusCode}');
print('NEXT BODY = ${response.body}');
  return jsonDecode(response.body);
}

static Future<Map<String, dynamic>> subscribeFgSante({
  required String planType,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/health/subscribe'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'planType': planType,
    }),
  );

  print('SUBSCRIBE STATUS: ${response.statusCode}');
  print('SUBSCRIBE BODY: ${response.body}');

  if (response.body.isEmpty || response.body == 'null') {
    return {};
  }

  return jsonDecode(response.body);
}

static Future<List<dynamic>> getMyPrescriptions() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/health/my-prescriptions'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  print('MY PRESCRIPTIONS: $data');

  if (response.statusCode == 200 &&
      data['success'] == true) {
    return data['prescriptions'] ?? [];
  }

  return [];
}

static Future<List<dynamic>> getAdminPrescriptions() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/health/admin/prescriptions'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data['prescriptions'] ?? [];
  }

  return [];
}

static Future<Map<String, dynamic>> bookAppointment({
  required int doctorId,
  required String doctorName,
  required String clinicName,
  required String appointmentDate,
  required String appointmentTime,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('$baseUrl/book-appointment'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'doctorId': doctorId,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
    }),
  );

  final data = jsonDecode(response.body);
  return data;
}

static Future<List<dynamic>> getDoctorUnavailabilities() async {
  final token = await AuthService.getToken();

  final response = await http.get(
      Uri.parse('$baseUrl/doctor-unavailability'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data['unavailabilities'] ?? [];
  }

  return [];
}

static Future<List<dynamic>> getDoctorAvailabilities() async {

final token = await AuthService.getToken();
  

  final response = await http.get(
    Uri.parse('$baseUrl/doctor-availability'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print(response.body);

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 &&
      data['success'] == true) {

    return data['availabilities'] ?? [];
  }

  return [];
}

static Future<Map<String, dynamic>> getStats() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
    Uri.parse('$baseUrl/stats'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('HEALTH STATS STATUS: ${response.statusCode}');
  print('HEALTH STATS BODY: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  }

  return {
    'doctors': 0,
    'appointments': 0,
    'results': 0,
    'prescriptions': 0,
  };
}

static Future<Map<String, dynamic>> getHealthStats() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/health/stats'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

 print('STATS URL = ${ApiConfig.baseUrl}/api/health/stats');
print('STATS STATUS = ${response.statusCode}');
print('STATS BODY = ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    return data;
  }

  return {
    'doctors': 0,
    'results': 0,
    'appointments': 0,
    'prescriptions': 0,
  };
}


static Future<Map<String, dynamic>> subscribeFgSanteWallet({
  required String planType,
  required String pin,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/health/subscribe-wallet'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'planType': planType,
      'pin': pin,
    }),
  );

  print('SUBSCRIBE WALLET STATUS: ${response.statusCode}');
  print('SUBSCRIBE WALLET BODY: ${response.body}');

  return jsonDecode(response.body);
}

static Future<List<dynamic>> getPrescriptions() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse(
      '${ApiConfig.baseUrl}/api/health/prescriptions',
    ),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('PRESCRIPTIONS RESPONSE: ${response.body}');

  final data = jsonDecode(response.body);

  if (data['success'] == true) {
    return data['prescriptions'] ?? [];
  }

  return [];
}


  static Future<List<dynamic>> getMedicalRecords() async {
  try {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/health/records'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

 print('RECORDS STATUS: ${response.statusCode}');
  print('RECORDS BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['records'] ?? [];
    }

    return [];
  } catch (e) {
    print('getMedicalRecords error: $e');
    return [];
  }
}

static Future<Map<String, dynamic>> addMedicalRecord({
  required String patientPhone,
  required String title,
  required String category,
  required String notes,
  required String doctorName,
  required String clinicName,
  PlatformFile? file,
  required int patientId,
}) async {

  final token = await AuthService.getToken();

  var request = http.MultipartRequest(
    'POST',
    Uri.parse(
      '${ApiConfig.baseUrl}/api/health/records',
    ),
  );

  request.headers['Authorization'] =
      'Bearer $token';

  request.fields['patientPhone'] =
      patientPhone;

  request.fields['title'] =
      title;

  request.fields['category'] =
      category;

  request.fields['notes'] =
      notes;

  request.fields['doctorName'] =
      doctorName;

  request.fields['clinicName'] =
      clinicName;

if (file != null && file.bytes != null) {
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      file.bytes!,
      filename: file.name,
    ),
  );
}

 final response = await request.send();

final responseBody =
    await response.stream.bytesToString();

print('ADD RECORD STATUS: ${response.statusCode}');
print('ADD RECORD BODY: $responseBody');

if (response.statusCode == 200 ||
    response.statusCode == 201) {
  return jsonDecode(responseBody);
}

throw Exception(responseBody);
}


static Future<List<dynamic>> getAdminMedicalRecords() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/health/admin/medical-records'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data['records'] ?? [];
  }

  return [];
}

  static Future<Map<String, dynamic>> getRecords() async {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/health/records'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return jsonDecode(response.body);
  }

static Future<List<dynamic>> getMyAppointments() async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/health/my-appointments'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );
print('MY APPOINTMENTS STATUS: ${response.statusCode}');
print('MY APPOINTMENTS BODY: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 200 && data['success'] == true) {
    return data['appointments'] ?? [];
  }

  return [];
}

static Future<Map<String, dynamic>> cancelAppointment({
  required int appointmentId,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/health/appointments/$appointmentId/cancel'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  return jsonDecode(response.body);
}

static Future<List<dynamic>> getNotifications() async {

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  print('HEALTH URL => $baseUrl/notifications');

  final response = await http.get(
    Uri.parse('$baseUrl/notifications'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print('HEALTH NOTIFS STATUS: ${response.statusCode}');
  print('HEALTH NOTIFS BODY: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) return data;

    if (data['notifications'] != null) {
      return data['notifications'];
    }
  }

  return [];
}

static Future<Map<String, dynamic>> addAppointment({
  required String patientPhone,
  required String patientName,
  required String doctorName,
  required String clinicName,
  required String appointmentDate,
  required String appointmentTime,
  required String reason,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/health/appointments'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'patientPhone': patientPhone,
      'patientName': patientName,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'appointmentDate': appointmentDate,
      'appointmentTime': appointmentTime,
      'reason': reason,
    }),
  );

  return jsonDecode(response.body);
}


static Future<List<dynamic>> getAppointments(String phone) async {
  final token = await AuthService.getToken();

  final response = await http.get(
    Uri.parse('${ApiConfig.baseUrl}/api/health/appointments/$phone'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  final data = jsonDecode(response.body);

  if (data['success'] == true) {
    return data['appointments'] ?? [];
  }

  return [];
}


static Future<Map<String, dynamic>> savePatientProfile({
  required String fullName,
  required String phone,
  required String gender,
  required String dateOfBirth,
  required String bloodGroup,
  required String allergies,
  required String chronicDiseases,
  required String emergencyContactName,
  required String emergencyContactPhone,
  required String address,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/health/patient-profile'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fullName': fullName,
      'phone': phone,
      'gender': gender,
      'dateOfBirth': dateOfBirth,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicDiseases': chronicDiseases,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
      'address': address,
    }),
  );

print('STATUS CODE: ${response.statusCode}');
print('RESPONSE BODY: ${response.body}');

  return jsonDecode(response.body);
}

static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('token');
}


static Future<List> getPatientRecords(int patientId) async {
  final token = await getToken();

  final response = await http.get(
    Uri.parse('$baseUrl/medical-records/patient/$patientId'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  print('PATIENT RECORDS STATUS: ${response.statusCode}');
  print('PATIENT RECORDS BODY: ${response.body}');

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);

    if (data is List) return data;

    if (data['records'] != null) {
      return data['records'];
    }

    return [];
  }

  return [];
}

static Future<Map<String, dynamic>> subscribeFgSanteStripe({
  required String planType,
}) async {
  final token = await AuthService.getToken();

  final plans = {
    'monthly': 35,
    'quarterly': 100,
    'yearly': 350,
  };

  final amount = plans[planType];

  final response = await http.post(
    Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/pay-stripe'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'plan': planType,
      'amount': amount,
    }),
  );

  print('STRIPE STATUS: ${response.statusCode}');
  print('STRIPE BODY: ${response.body}');

  if (response.body.isEmpty) {
    return {
      'success': false,
      'message': 'Réponse Stripe vide',
    };
  }

  return jsonDecode(response.body);
}



static Future<Map<String, dynamic>> addDoctorAvailability({
  required String doctorName,
  required String clinicName,
  required String availableDate,
  required String startTime,
  required String endTime,
}) async {
  final token = await AuthService.getToken();

  final response = await http.post(
    
    Uri.parse('$baseUrl/doctor-availability'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'doctorName': doctorName,
      'clinicName': clinicName,
      'availableDate': availableDate,
      'startTime': startTime,
      'endTime': endTime,
    }),
  );

  return jsonDecode(response.body);
}




static Future<Map<String, dynamic>?> getPatientProfile() async {
  try {
    final token = await AuthService.getToken();

    final response = await http.get(
      
      Uri.parse('${ApiConfig.baseUrl}/api/health/patient-profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success']) {
      return data['profile'];
    }

    return null;
  } catch (e) {
    print('getPatientProfile error: $e');
    return null;
  }
}

}
