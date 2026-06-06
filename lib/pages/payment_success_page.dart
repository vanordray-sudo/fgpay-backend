import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'main_entry_page.dart';
import '../services/wallet_service.dart';

class PaymentSuccessPage extends StatefulWidget {
  final String sessionId;

  const PaymentSuccessPage({
    super.key,
    required this.sessionId,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  bool isLoading = true;
  String message = 'Confirmation du paiement...';
  double? balance;

 @override
void initState() {
  super.initState();

  final fullUrl = Uri.base.toString();

// ekstrè pati apre #
final hashPart = fullUrl.split('#').length > 1 ? fullUrl.split('#')[1] : '';

final uri = Uri.parse(hashPart.replaceFirst('/', ''));

final sessionIdFromUrl = uri.queryParameters['session_id'];

  if (sessionIdFromUrl != null) {
    confirmStripePayment(sessionIdFromUrl);
  } else {
    setState(() {
      isLoading = false;
      message = 'Session ID manke';
    });
  }
}

  Future<void> confirmStripePayment(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/stripe/confirm-checkout-session'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sessionId': widget.sessionId,
        }),
      );

      final data = jsonDecode(response.body);

     if (response.statusCode == 200 && data['success'] == true) {

  final newBalance = await WalletService.getBalance();

  if (!mounted) return;

  setState(() {
    isLoading = false;
    message = data['message'] ?? "Paiement confirmé";

    balance = newBalance; // 👉 SA KI ENPÒTAN
  });



        Future.delayed(const Duration(seconds: 3), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const MainEntryPage(),
            ),
          );
        });
      } else {
        setState(() {
          isLoading = false;
          message = data['message'] ?? 'Erreur confirmation session Stripe';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        message = 'Erreur confirmation Stripe: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement réussi'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 72,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (balance != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Nouveau solde: ${balance!.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MainEntryPage(),
                          ),
                        );
                      },
                      child: const Text('Retour au dashboard'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}