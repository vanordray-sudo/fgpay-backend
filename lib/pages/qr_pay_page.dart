import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/auth_service.dart';

class QrPayPage extends StatelessWidget {
  final int merchantId;
  final String merchantName;
  final double? amount;


  const QrPayPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = jsonEncode({
  'type': 'fgpay_qr',
  'merchantId': merchantId,
  'merchantName': merchantName,
  'amount': amount ?? 500, // 🔥 sa a enpòtan
});

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon QR Pay'),
      ),
      body: Center(
        child: Card(
          elevation: 4,
          margin: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scanner pou peye',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  merchantName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                if (amount != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${amount!.toStringAsFixed(2)} HTG',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 240,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}