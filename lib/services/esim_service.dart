import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class EsimService {
  static const String baseUrl = "http://127.0.0.1:3000";

  static Future<Map<String, dynamic>> buyEsim({
    required double amount,
    required String plan,
  }) async {
    final token = await AuthService.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/wallet/buy-esim'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'amount': amount,
        'plan': plan,
      }),
    );

    return jsonDecode(response.body);
  }
}