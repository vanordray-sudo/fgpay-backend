import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/wallet_service.dart';

class ScanQrPage extends StatefulWidget {
  final Future<void> Function() onPaymentDone;

  const ScanQrPage({
    super.key,
    required this.onPaymentDone,
  });

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  bool _handled = false;

  Future<void> _handleQr(String rawValue) async {
    if (_handled) return;
    _handled = true;

    try {
      final data = jsonDecode(rawValue);

      if (data['type'] != 'fgpay_qr') {
        throw Exception('QR FGPay pa valab');
      }

      final merchantId = data['merchantId'];
      final merchantName = (data['merchantName'] ?? 'Merchant').toString();
      final qrAmount = data['amount'];

      if (!mounted) return;

      final amountController = TextEditingController(
        text: qrAmount == null ? '' : qrAmount.toString(),
      );

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('QR Pay'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Merchant: $merchantName'),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Montant',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Kontinye'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final amount = double.tryParse(amountController.text.trim());

      if (amount == null || amount <= 0) {
        throw Exception('Montant invalide');
      }

      if (!mounted) return;

      final pinController = TextEditingController();

      final pin = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('PIN Sécurité'),
            content: TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Entrez votre PIN',
                border: OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, pinController.text.trim()),
                child: const Text('Valider'),
              ),
            ],
          );
        },
      );

      if (pin == null || pin.isEmpty) {
        if (mounted) Navigator.pop(context);
        return;
      }

      final result = await WalletService.qrPay(
        merchantId: merchantId,
        amount: amount,
        pin: pin,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await widget.onPaymentDone();

        if (!mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paiement QR réussi: -${amount.toStringAsFixed(2)} HTG',
            ),
          ),
        );
      } else {
        _handled = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result['message'] ?? 'Erreur QR Pay').toString()),
          ),
        );
      }
    } catch (e) {
      _handled = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('QR invalide: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          final rawValue = barcode.rawValue;
          if (rawValue != null) {
            _handleQr(rawValue);
          }
        },
      ),
    );
  }
}