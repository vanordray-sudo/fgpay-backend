import 'package:flutter/material.dart';

class EsimResultPage extends StatelessWidget {
  final String qrCode;
  final String activationCode;
  final String planName;
  final double price;

  const EsimResultPage({
    super.key,
    required this.qrCode,
    required this.activationCode,
    required this.planName,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSIM activée'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              planName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paiement effectué: \$${price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (qrCode.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  qrCode,
                  width: 220,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      width: 220,
                      height: 220,
                      alignment: Alignment.center,
                      color: Colors.grey.shade200,
                      child: const Text('QR code indisponible'),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            SelectableText(
              'Code activation: $activationCode',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}