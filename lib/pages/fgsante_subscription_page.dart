import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FgSanteSubscriptionPage extends StatefulWidget {
  const FgSanteSubscriptionPage({super.key});

  @override
  State<FgSanteSubscriptionPage> createState() =>
      _FgSanteSubscriptionPageState();
}

class _FgSanteSubscriptionPageState
    extends State<FgSanteSubscriptionPage> {

     bool isLoading = false;
String message = '';
Map<String, dynamic>? activeSubscription;
bool subscriptionLoading = true;

@override
void initState() {
  super.initState();
  _loadSubscription();
}

Future<void> _loadSubscription() async {
  try {
    final prefs =
        await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      if (!mounted) return;

      setState(() {
        activeSubscription = null;
        subscriptionLoading = false;
      });

      return;
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

    print(
      'FG SANTE SUBSCRIPTION STATUS = '
      '${response.statusCode}',
    );

    print(
      'FG SANTE SUBSCRIPTION BODY = '
      '${response.body}',
    );

    if (!mounted) return;

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final subscription = data['subscription'];

      if (subscription != null &&
          subscription['status'] == 'active') {
        setState(() {
          activeSubscription =
              Map<String, dynamic>.from(
            subscription,
          );
          subscriptionLoading = false;
        });

        return;
      }
    }

    setState(() {
      activeSubscription = null;
      subscriptionLoading = false;
    });
  } catch (e) {
    print(
      'FG SANTE LOAD SUBSCRIPTION ERROR = $e',
    );

    if (!mounted) return;

    setState(() {
      activeSubscription = null;
      subscriptionLoading = false;
    });
  }
}

Future<void> _payWithStripe({
  required BuildContext context,
  required String plan,
  required double amount,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();

final token = prefs.getString('token');

if (token == null || token.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Session introuvable. Veuillez vous reconnecter.',
      ),
    ),
  );
  return;
}
   final response = await http.post(
  Uri.parse(
    '${ApiConfig.baseUrl}/api/fgsante/subscriptions/pay-stripe',
  ),
     headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $token',
},
      body: jsonEncode({
        'plan': plan,
        'amount': amount,
      }),
    );

   if (response.statusCode < 200 ||
    response.statusCode >= 300) {
  throw Exception(
    'Erreur ${response.statusCode} : ${response.body}',
  );
}

    final data = jsonDecode(response.body);

    final checkoutUrl =
        data['url'] ?? data['checkout_url'];

    if (checkoutUrl == null) {
      throw Exception(
        'URL Stripe introuvable.',
      );
    }

    await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Erreur de paiement : $e',
        ),
      ),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('FG Santé Pro'),
      backgroundColor: Colors.green,
    ),

    body: subscriptionLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )

        // ✅ ABÒNMAN DEJA AKTIF
        : activeSubscription != null
            ? _buildActiveSubscription()

            // ✅ PA GEN ABÒNMAN AKTIF
            : SingleChildScrollView(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.medical_services,
                      size: 80,
                      color: Colors.green,
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Choisissez votre abonnement',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    _planCard(
                      context,
                      'Mensuel',
                      '\$35 / mois',
                      'monthly',
                      [
                        'Rendez-vous illimités',
                        'Ordonnances numériques',
                        'Références médicales',
                        'Dossiers patients',
                      ],
                    ),

                    const SizedBox(height: 20),

                    _planCard(
                      context,
                      'Trimestriel',
                      '\$100 / trimestre',
                      'quarterly',
                      [
                        'Toutes les fonctions Pro',
                        'Économie sur le prix',
                        'Support prioritaire',
                      ],
                    ),

                    const SizedBox(height: 20),

                    _planCard(
                      context,
                      'Annuel',
                      '\$350 / an',
                      'yearly',
                      [
                        'Toutes les fonctions',
                        'Badge Professionnel Vérifié',
                        'Support Premium',
                      ],
                    ),
                  ],
                ),
              ),
  );
}
Widget _buildActiveSubscription() {
  final subscription = activeSubscription!;

  final String plan =
      subscription['plan']?.toString() ?? '';

  final String status =
      subscription['status']?.toString() ?? '';

  final double amount =
      double.tryParse(
        subscription['amount']?.toString() ??
            '0',
      ) ??
      0;

  final String currency =
      subscription['currency']
              ?.toString()
              .toUpperCase() ??
          'USD';

  final DateTime? startedAt =
      DateTime.tryParse(
    subscription['started_at']?.toString() ??
        '',
  );

  final DateTime? expiresAt =
      DateTime.tryParse(
    subscription['expires_at']?.toString() ??
        '',
  );

  int daysRemaining = 0;

  if (expiresAt != null) {
    daysRemaining =
        expiresAt
            .difference(DateTime.now())
            .inDays +
        1;

    if (daysRemaining < 0) {
      daysRemaining = 0;
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final day =
        date.day.toString().padLeft(2, '0');
    final month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String planLabel;

  switch (plan) {
    case 'monthly':
      planLabel = 'Mensuel';
      break;

    case 'quarterly':
      planLabel = 'Trimestriel';
      break;

    case 'yearly':
      planLabel = 'Annuel';
      break;

    default:
      planLabel = plan;
  }

  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(
          maxWidth: 600,
        ),
        child: Card(
          elevation: 4,
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(
                  Icons.workspace_premium,
                  size: 70,
                  color: Colors.green,
                ),

                const SizedBox(height: 15),

                const Text(
                  'Mon abonnement FG Santé',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Votre abonnement professionnel '
                  'FG Santé est actif',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 25),

                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green
                        .withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        planLabel,
                        style:
                            const TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 10,
                      ),

                      Text(
                        '${amount.toStringAsFixed(2)} '
                        '$currency',
                        style:
                            const TextStyle(
                          fontSize: 30,
                          fontWeight:
                              FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                _subscriptionInfoRow(
                  'Statut',
                  status == 'active'
                      ? 'Actif'
                      : status,
                ),

                _subscriptionInfoRow(
                  'Date d’activation',
                  formatDate(startedAt),
                ),

                _subscriptionInfoRow(
                  'Date d’expiration',
                  formatDate(expiresAt),
                ),

                _subscriptionInfoRow(
                  'Jours restants',
                  '$daysRemaining jours',
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: const Icon(
                      Icons.check_circle,
                    ),
                    label: const Text(
                      'Abonnement actif',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          Colors.green
                              .withOpacity(
                        0.65,
                      ),
                      disabledForegroundColor:
                          Colors.white,
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _subscriptionInfoRow(
  String label,
  String value,
) {
  return Padding(
    padding:
        const EdgeInsets.symmetric(
      vertical: 8,
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
}
 
Widget _planCard(
  BuildContext context,
  String title,
  String price,
  String planType,
  List<String> features,
) {
  return Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            price,
            style: const TextStyle(
              fontSize: 28,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      feature,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (planType == 'monthly') {
                  _payWithStripe(
                    context: context,
                    plan: 'monthly',
                    amount: 35.0,
                  );
                } else if (
                    planType == 'quarterly') {
                  _payWithStripe(
                    context: context,
                    plan: 'quarterly',
                    amount: 100.0,
                  );
                } else if (
                    planType == 'yearly') {
                  _payWithStripe(
                    context: context,
                    plan: 'yearly',
                    amount: 350.0,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Souscrire',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
 
}