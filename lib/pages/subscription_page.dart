import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';


class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() =>
      _SubscriptionPageState();
}

class _SubscriptionPageState
    extends State<SubscriptionPage> {

      bool isLoading = true;
String message = '';

Map<String, dynamic>? subscription;

@override
void initState() {
  super.initState();
  _loadSubscription();
}

Future<void> _loadSubscription() async {
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

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/fgsante/subscriptions/me',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data =
        jsonDecode(response.body);

    if (response.statusCode == 404) {
      if (!mounted) return;

      setState(() {
        subscription = null;
        isLoading = false;
      });

      return;
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(
        data['message'] ??
            'Erreur lors du chargement de l’abonnement.',
      );
    }

    if (!mounted) return;

    setState(() {
      subscription =
          data['subscription'];
      isLoading = false;
    });
  } catch (e) {
    if (!mounted) return;

    setState(() {
      message = e.toString();
      isLoading = false;
    });
  }
}
String _formatPlan(String? plan) {
  switch (plan) {
    case 'monthly':
      return 'Mensuel';
    case 'quarterly':
      return 'Trimestriel';
    case 'yearly':
      return 'Annuel';
    default:
      return plan ?? '-';
  }
}

String _formatDate(dynamic value) {
  if (value == null) return '-';

  final date =
      DateTime.tryParse(value.toString());

  if (date == null) return '-';

  final day =
      date.day.toString().padLeft(2, '0');
  final month =
      date.month.toString().padLeft(2, '0');

  return '$day/$month/${date.year}';
}

int _remainingDays(dynamic value) {
  if (value == null) return 0;

  final expiresAt =
      DateTime.tryParse(value.toString());

  if (expiresAt == null) return 0;

  final difference =
      expiresAt.difference(DateTime.now());

  if (difference.isNegative) {
    return 0;
  }

  return difference.inDays;
}

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        title: const Text(
          'Abonnement FG Santé',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
    ? const Center(
        child: CircularProgressIndicator(),
      )
    : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                 child: const Icon(
  Icons.health_and_safety,
  color: Colors.green,
  size: 38,
),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Plan Professionnel FG Santé',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Accédez aux services professionnels FG Santé avec un seul abonnement',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
               if (subscription != null)
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF2F80ED),
          Color(0xFF56CCF2),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Text(
          _formatPlan(
            subscription?['plan'],
          ),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          '${subscription?['amount']} '
          '${subscription?['currency']}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
                const SizedBox(height: 24),
               const Align(
  alignment: Alignment.centerLeft,
  child: Text(
    'Services inclus :',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
),

const SizedBox(height: 12),

const _SubscriptionFeature(
  text: 'Dashboard professionnel',
),
const _SubscriptionFeature(
  text: 'Gestion des rendez-vous',
),
const _SubscriptionFeature(
  text: 'Prescriptions médicales',
),
const _SubscriptionFeature(
  text: 'Gestion des dossiers patients',
),
const _SubscriptionFeature(
  text: 'Références médicales',
),
                const SizedBox(height: 24),

                if (subscription != null) ...[
  const SizedBox(height: 24),

  _SubscriptionInfoRow(
    label: 'Statut',
    value:
        subscription?['status'] == 'active'
            ? 'Actif'
            : 'Expiré',
  ),

  _SubscriptionInfoRow(
    label: 'Date d’activation',
    value: _formatDate(
      subscription?['started_at'],
    ),
  ),

  _SubscriptionInfoRow(
    label: 'Date d’expiration',
    value: _formatDate(
      subscription?['expires_at'],
    ),
  ),

  _SubscriptionInfoRow(
    label: 'Jours restants',
    value:
        '${_remainingDays(subscription?['expires_at'])} jours',
  ),

],
               const SizedBox(height: 20),

if (subscription != null)
  SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: null,
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: Colors.green,
        disabledForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Abonnement actif',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubscriptionFeature extends StatelessWidget {
  final String text;

  const _SubscriptionFeature({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _SubscriptionInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _SubscriptionInfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}