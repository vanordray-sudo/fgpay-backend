import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'main_entry_page.dart';

class PayPalSuccessPage extends StatefulWidget {
  final String orderId;

  const PayPalSuccessPage({
    super.key,
    required this.orderId,
  });

  @override
  State<PayPalSuccessPage> createState() => _PayPalSuccessPageState();
}

class _PayPalSuccessPageState extends State<PayPalSuccessPage> {
  bool isLoading = true;
  String message = 'Confirmation du paiement PayPal...';
  double? balance;

  @override
  void initState() {
    super.initState();
    capturePayPalOrder();
  }

  Future<void> capturePayPalOrder() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/paypal/capture-order'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'orderId': widget.orderId,
        }),
      );

      print('PAYPAL CAPTURE STATUS = ${response.statusCode}');
      print('PAYPAL CAPTURE BODY = ${response.body}');

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          isLoading = false;
          message = data['message'] ?? 'Paiement PayPal confirmé';
          balance = data['balance'] != null
              ? (data['balance'] as num).toDouble()
              : null;
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
          message = data['message'] ?? 'Erreur capture order PayPal';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        message = 'Erreur PayPal: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement PayPal réussi'),
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