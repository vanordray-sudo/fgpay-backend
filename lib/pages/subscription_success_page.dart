import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';



class SubscriptionSuccessPage extends StatefulWidget {
  const SubscriptionSuccessPage({
    super.key,
    required this.sessionId,
  });

  final String sessionId;

  @override
  State<SubscriptionSuccessPage> createState() =>
      _SubscriptionSuccessPageState();
}

class _SubscriptionSuccessPageState
    extends State<SubscriptionSuccessPage> {
  bool _loading = true;
  bool _success = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _confirmSubscription();
  }

  Future<void> _confirmSubscription() async {
    try {
      final prefs =
          await SharedPreferences.getInstance();

      final token =
          prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception(
          'Session utilisateur introuvable.',
        );
      }

      final response = await http.post(
        Uri.parse(
          '${ApiConfig.baseUrl}/api/fgsante/subscriptions/confirm',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'session_id': widget.sessionId,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          data['message'] ??
              'Erreur de confirmation.',
        );
      }

      if (!mounted) return;

      setState(() {
        _success = true;
        _message =
            'Votre abonnement FG Santé est maintenant actif.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _success = false;
        _message = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Abonnement FG Santé',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      _success
                          ? Icons.check_circle
                          : Icons.error,
                      size: 80,
                      color: _success
                          ? Colors.green
                          : Colors.red,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      _success
                          ? 'Paiement confirmé'
                          : 'Erreur de confirmation',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _message,
                      textAlign:
                          TextAlign.center,
                    ),

                    const SizedBox(height: 28),

                    if (_success)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                            '/professional-dashboard',
                            (route) => false,
                          );
                        },
                        child: const Text(
                          'Accéder à mon espace',
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}