import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StripePaymentPage extends StatefulWidget {
  const StripePaymentPage({super.key});

  @override
  State<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  final TextEditingController amountController = TextEditingController();
  bool isLoading = false;

  Future<void> startStripePayment() async {
    final amountText = amountController.text.trim();
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/stripe/create-checkout-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'serviceName': 'FGPay Recharge',
          'amount': amount,
          'currency': 'eur',
          'userId': 3,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final checkoutUrl = data['checkoutUrl'];

        if (checkoutUrl != null && checkoutUrl.toString().isNotEmpty) {
          html.window.location.href = checkoutUrl.toString();
        } else {
          throw 'Impossible d’ouvrir Stripe';
        }
      } else {
        throw data['message'] ?? 'Erreur création session Stripe';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Stripe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Montant (€)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : startStripePayment,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Payer avec Stripe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}