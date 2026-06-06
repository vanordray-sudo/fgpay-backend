import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ProfessionalService {
 static const String baseUrl =
'https://fgpay-backend-production.up.railway.app/api/health/professionals';
  static Future<String> getMyStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/me/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data['status'] ?? 'pending';
    }

    return 'pending';
  }

static Future<http.Response> approveProfessional(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  return http.put(
    Uri.parse('$baseUrl/$id/approve'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}

static Future<http.Response> rejectProfessional(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  return http.put(
    Uri.parse('$baseUrl/$id/reject'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
}

}