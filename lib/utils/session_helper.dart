import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';

class SessionHelper {
  static Future<void> handleUnauthorized(BuildContext context) async {
    await AuthService.clearSession();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expirée. Reconnecte-toi.'),
      ),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}