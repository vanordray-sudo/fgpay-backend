import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class FgSanteSubscriptionPage extends StatelessWidget {
  const FgSanteSubscriptionPage({super.key});


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FG Santé Pro'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
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
                fontWeight: FontWeight.bold,
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

            const SizedBox(height: 15),

            ...features.map(
              (e) => ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
                title: Text(e),
              ),
            ),

            const SizedBox(height: 15),

            ElevatedButton(
        onPressed: () async {
  final paymentMethod = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choisir le paiement'),
      content: Text('Souscrire au plan $title'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'wallet'),
          child: const Text('FGPay Wallet'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, 'stripe'),
          child: const Text('Carte / Stripe'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ],
    ),
  );

  if (paymentMethod == null) return;

  if (paymentMethod == 'wallet') {
    final pinController = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PIN sécurité'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Entrez votre PIN',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              context,
              pinController.text.trim(),
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );

    if (pin == null || pin.isEmpty) return;

    final data = await HealthService.subscribeFgSanteWallet(
      planType: planType,
      pin: pin,
    );

if (data['success'] == true && data['newBalance'] != null) {
  final newBalance = double.parse(data['newBalance'].toString());

  final prefs = await SharedPreferences.getInstance();

  await prefs.setDouble('balance', newBalance);

  final userString = prefs.getString('user');

  if (userString != null) {
    final userMap = jsonDecode(userString);
    userMap['balance'] = newBalance;

    await prefs.setString('user', jsonEncode(userMap));
  }
}


    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? 'Erreur abonnement')),
      );

     if (data['success'] == true) {
  Navigator.pop(context, true);
}
    }
  }

  if (paymentMethod == 'stripe') {
  final data = await HealthService.subscribeFgSanteStripe(
    planType: planType,
  );

  if (!context.mounted) return;

  if (data['success'] == true && data['checkoutUrl'] != null) {
    final url = Uri.parse(data['checkoutUrl']);

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(data['message'] ?? 'Erreur Stripe'),
      ),
    );
  }
}
},
              child: const Text('Souscrire'),
            ),
          ],
        ),
      ),
    );
  }
}