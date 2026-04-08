import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/stripe_service.dart';

class StripePaymentPage extends StatefulWidget {
  const StripePaymentPage({super.key});

  @override
  State<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  bool isLoading = false;

  Future<void> handlePayment() async {
    setState(() {
      isLoading = true;
    });

    final url = await StripeService.createCheckoutSession(
      serviceName: 'FGPay IPTV',
      amount: 9.99,
    );

    setState(() {
      isLoading = false;
    });

    if (url != null && url.isNotEmpty) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur Stripe')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement Stripe'),
      ),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: handlePayment,
                child: const Text('Peye ak kat 💳'),
              ),
      ),
    );
  }
}