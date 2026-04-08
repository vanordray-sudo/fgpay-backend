import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {
  static const String _tokenKey = 'token';
  static const String _userKey = 'user';
  static const String _balanceKey = 'balance';

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phone': phone.trim(),
          'password': password.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();

        final token = data['token'];
        final user = Map<String, dynamic>.from(data['user'] ?? {});

        await prefs.setString(_tokenKey, token ?? '');
        await prefs.setString(_userKey, jsonEncode(user));

        final balance = _toDouble(user['balance']);
        await prefs.setDouble(_balanceKey, balance);

        return {
          'success': true,
          'token': token,
          'user': user,
        };
      }

      return {
        'success': false,
        'message': data['message'] ?? 'Login failed',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur login: $e',
      };
    }
  }


static Future<void> logout() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // 🔥 efase tout token
}

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawUser = prefs.getString(_userKey);

      if (rawUser == null || rawUser.isEmpty) {
        return {};
      }

      return Map<String, dynamic>.from(jsonDecode(rawUser));
    } catch (_) {
      return {};
    }
  }

static Future<List<Map<String, dynamic>>> getStoredTransactions() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('transactions');

  if (raw == null || raw.isEmpty) return [];

  final decoded = jsonDecode(raw) as List;
  return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
}

static Future<void> saveStoredTransactions(
  List<Map<String, dynamic>> transactions,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('transactions', jsonEncode(transactions));
}

  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user));

    if (user.containsKey('balance')) {
      await prefs.setDouble(_balanceKey, _toDouble(user['balance']));
    }
  }

 static Future<void> updateStoredBalance(double balance) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setDouble(_balanceKey, balance);

  final user = await getCurrentUser();
  if (user.isNotEmpty) {
    user['balance'] = balance;
    await prefs.setString(_userKey, jsonEncode(user));
  }
}

 static Future<double> getStoredBalance() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getDouble('balance') ?? 0;
}


  static Map<String, String> authHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}