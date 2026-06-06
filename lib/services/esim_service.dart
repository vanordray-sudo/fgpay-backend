import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EsimService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/esim';
    }
    return 'http://10.0.2.2:3000/api/esim';
  }

  Future<List<dynamic>> fetchPlans() async {
    final response = await http.get(
      Uri.parse('$baseUrl/plans'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur chargement plans eSIM');
    }

    return data['plans'] ?? [];
  }

  Future<Map<String, dynamic>> purchase({
    required int planId,
    required String pin,
  }) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }


    
    print('ESIM purchase token: $token');
    print('ESIM purchase body: ${jsonEncode({
      'planId': planId,
      'pin': pin,
    })}');
 
  final url = Uri.parse('${ApiConfig.baseUrl}/api/esim/buy');

print('ESIM TOKEN: $token');

final response = await http.post(
  url,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'planId': planId,
    'pin': pin,
  }),
);

print('ESIM purchase STATUS: ${response.statusCode}');
print('ESIM purchase BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('SESSION_EXPIRED');
    }

    if (response.statusCode != 200) {
      throw Exception(data['error'] ?? data['message'] ?? 'Erreur achat eSIM');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> buyEsim({
  required String planId,
  required String pin,
}) async {

 final prefs = await SharedPreferences.getInstance();
final token = prefs.getString('token');

final url = Uri.parse('${ApiConfig.baseUrl}/api/esim/buy');

print('ESIM TOKEN: $token');


final response = await http.post(
  url,
  headers: {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  },
  body: jsonEncode({
    'planId': planId,
    'pin': pin,
  }),
); 

  print('ESIM STATUS: ${response.statusCode}');
  print('ESIM BODY: ${response.body}');

  final data = jsonDecode(response.body);

  if (response.statusCode == 401) {
    throw Exception('SESSION_EXPIRED');
  }

  return data;
}
  
  Future<List<dynamic>> fetchMyLines() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/my-lines'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('SESSION_EXPIRED');
    }

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur chargement mes eSIM');
    }

    return data['lines'] ?? [];
  }

  Future<Map<String, dynamic>> fetchLine(int id) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/line/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('SESSION_EXPIRED');
    }

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur chargement ligne eSIM');
    }

    return Map<String, dynamic>.from(data['line']);
  }
}