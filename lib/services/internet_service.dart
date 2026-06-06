import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/internet_plan_model.dart';
import '../services/auth_service.dart';

class InternetService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/internet';
    }
    return 'http://10.0.2.2:3000/api/internet';
  }

  Future<List<InternetPlan>> fetchPlans() async {
    final url = Uri.parse('$baseUrl/plans');

    print('INTERNET fetchPlans URL: $url');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('INTERNET fetchPlans STATUS: ${response.statusCode}');
    print('INTERNET fetchPlans BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur chargement plans');
    }

    final List plans = data['plans'] ?? [];
    return plans.map((e) => InternetPlan.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> buyPlan(int planId) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session absente');
    }

    final url = Uri.parse('$baseUrl/buy-plan');

    print('INTERNET buyPlan URL: $url');
    print('INTERNET buyPlan TOKEN: $token');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'planId': planId}),
    );

    print('INTERNET buyPlan STATUS: ${response.statusCode}');
    print('INTERNET buyPlan BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('SESSION_EXPIRED');
    }

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur achat plan');
    }

    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>?> fetchMySubscription() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session absente');
    }

    final url = Uri.parse('$baseUrl/my-subscription');

    print('INTERNET fetchMySubscription URL: $url');
    print('INTERNET fetchMySubscription TOKEN: $token');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('INTERNET fetchMySubscription STATUS: ${response.statusCode}');
    print('INTERNET fetchMySubscription BODY: ${response.body}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 401) {
      throw Exception('SESSION_EXPIRED');
    }

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Erreur récupération abonnement');
    }

    if (data['subscription'] == null) return null;
    return Map<String, dynamic>.from(data['subscription']);
  }
}