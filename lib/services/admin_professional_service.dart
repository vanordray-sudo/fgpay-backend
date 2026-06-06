import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_professional_service.dart';

class AdminProfessionalService {
  static const String baseUrl =
'http://127.0.0.1:3000/api/professionals';

 static Future<List<dynamic>> getPendingProfessionals() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.get(
  Uri.parse('$baseUrl/pending'),
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
);

print("CALL URL: $baseUrl/pending");

print('PENDING STATUS: ${response.statusCode}');
print('PENDING BODY: ${response.body}');

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  return data['professionals'] ?? [];
}

return [];
 }

  static Future<bool> approveProfessional(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.put(
    Uri.parse('$baseUrl/$id/approve'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('APPROVE STATUS: ${response.statusCode}');
  print('APPROVE BODY: ${response.body}');

  return response.statusCode == 200;
}

 static Future<bool> rejectProfessional(int id) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final response = await http.put(
    Uri.parse('$baseUrl/$id/reject'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  print('REJECT STATUS: ${response.statusCode}');
  print('REJECT BODY: ${response.body}');

  return response.statusCode == 200;
} 
}