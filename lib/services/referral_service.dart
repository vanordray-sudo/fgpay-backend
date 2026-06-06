import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/referral_service.dart';
import '../config/api_config.dart';

class ReferralService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'http://10.0.2.2:3000';
    }
  }
static Future<String?> _getToken() async {
   final prefs =
        await SharedPreferences.getInstance();
        return prefs.getString('token');
}
  

 static Future<List<dynamic>> getPatientReferences() async {
  final token = await _getToken();

  final response = await http.get(
    Uri.parse('$baseUrl/api/referrals/patient'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print("REFERENCES STATUS: ${response.statusCode}");
  print("REFERENCES BODY: ${response.body}");

  if (response.statusCode == 200) {
  final decoded = jsonDecode(response.body);
  return decoded['referrals'] ?? [];
}

  return [];
}


  static Future<Map<String, dynamic>> createReferral({
    required int patientId,
    required int specialtyId,
    required String reason,
    required String priority,
  }) async {

    try {

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
         Uri.parse('$baseUrl/api/referrals/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patient_id': patientId,
          'to_specialty_id': specialtyId,
          'reason': reason,
          'priority': priority,
        }),
      );
print('REFERRAL STATUS: ${response.statusCode}');
print('REFERRAL BODY: ${response.body}');


      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'referral': data['referral'],
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Erreur',
      };

    } catch (e) {

      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }


  /*
  =========================
  CREATE REFERRAL
  =========================
  */

 static Future<Map<String, dynamic>> updateReferralStatus({
  required int referralId,
  required String status,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.put(
     Uri.parse ('$baseUrl/api/referrals/$referralId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
      }),
    );

    print('UPDATE REFERRAL STATUS CODE: ${response.statusCode}');
    print('UPDATE REFERRAL BODY: ${response.body}');

    return jsonDecode(response.body);
  } catch (e) {
    print('UPDATE REFERRAL ERROR: $e');

    return {
      'success': false,
      'message': e.toString(),
    };
  }
}
  
  /*
  =========================
  DOCTOR REFERRALS
  =========================
  */

  static Future<List<dynamic>> getDoctorReferrals() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/referrals/doctor'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return data['referrals'];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /*
  =========================
  PATIENT REFERRALS
  =========================
  */

  static Future<List<dynamic>> getPatientReferrals() async {
    try {
      final token = await _getToken();

      final response = await http.get(
        Uri.parse('$baseUrl/api/referrals/patient'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        return data['referrals'];
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /*
  =========================
  UPDATE STATUS
  =========================
  */

  static Future<Map<String, dynamic>> updateStatus({
    required int referralId,
    required String status,
  }) async {
    try {
      final token = await _getToken();

      final response = await http.put(
        Uri.parse(
          '$baseUrl/api/referrals/status/$referralId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'status': status,
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}