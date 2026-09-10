import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class AuthService {
 static const _tokenKey = 'token';
static const _userKey = 'user';

 static Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('token'); // ✔️ menm kle a
  await prefs.remove('user');
}

  static Future<void> logout() async {
    await clearSession();
  }

static Future<void> saveSession(String token, Map<String, dynamic> user) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
  await prefs.setString(_userKey, jsonEncode(user));
  print('TOKEN SAVED: $token');
  print('SESSION USER SAVED = $user');
}

static Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString(_tokenKey);
  print('TOKEN READ: $token');
  return token;
}

static Future<String> getHealthRole() async {
  final user = await getUser();

  print('USER DATA: $user');

  return user?['health_role'] ?? 'patient';
}

static Future<String> getUserName() async {
  final user = await getUser();

  print('USER DATA NAME CHECK = $user');

  return user?['full_name'] ??
      user?['name'] ??
      'Utilisateur';
}

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }


}