import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PayPalPaymentPage extends StatefulWidget {
  const PayPalPaymentPage({super.key});

  @override
  State<PayPalPaymentPage> createState() => _PayPalPaymentPageState();
}

class _PayPalPaymentPageState extends State<PayPalPaymentPage> {
  final TextEditingController amountController =
      TextEditingController(text: '10');

  bool isLoading = false;
  String errorMessage = '';

  Future<void> createPayPalOrder() async {
    final amount = double.tryParse(amountController.text.trim());

    if (amount == null || amount <= 0) {
      setState(() {
        errorMessage = 'Montant invalide';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/paypal/create-order'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'serviceName': 'FGPay Recharge',
          'amount': amount,
          'currency': 'EUR',
          'userId': 3,
        }),
      );

      print('PAYPAL STATUS = ${response.statusCode}');
      print('PAYPAL BODY = ${response.body}');

      if (response.body.trim().startsWith('<')) {
        throw Exception('Backend PayPal pa retounen JSON.');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final approvalUrl = data['approvalUrl']?.toString();

        if (approvalUrl == null || approvalUrl.isEmpty) {
          setState(() {
            isLoading = false;
            errorMessage = 'approvalUrl PayPal manke';
          });
          return;
        }

        html.window.location.href = approvalUrl;
      } else {
        setState(() {
          isLoading = false;
          errorMessage = data['message']?.toString() ??
              data['error']?.toString() ??
              'Erreur création order PayPal';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = 'Erreur PayPal: $e';
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
        title: const Text('Paiement PayPal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : createPayPalOrder,
                child: Text(
                  isLoading ? 'Chargement...' : 'Payer avec PayPal',
                ),
              ),
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }
}