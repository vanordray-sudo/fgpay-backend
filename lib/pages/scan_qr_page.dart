import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'pay_page.dart';

class ScanQrPage extends StatefulWidget {
  final Future<void> Function()? onPaymentDone;

  const ScanQrPage({
    super.key,
    this.onPaymentDone,
  });

  @override
  State<ScanQrPage> createState() => _ScanQrPageState();
}

class _ScanQrPageState extends State<ScanQrPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showEsimDialog(String code) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('eSIM détectée'),
        content: SelectableText(
          'Sa a se yon QR eSIM.\n\n'
          'Pou aktive li:\n'
          '1. Ale nan Paramètres telefòn ou\n'
          '2. Chèche Mobile Network / Données cellulaires\n'
          '3. Chwazi Ajouter eSIM\n'
          '4. Scanner QR sa a\n\n'
          'Code:\n$code',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _openPayPage(Map<String, dynamic> data) async {
    final merchantIdRaw = data['merchantId'];
    final merchantNameRaw = data['merchantName'];
    final amountRaw = data['amount'];

    if (merchantIdRaw == null || amountRaw == null) {
      throw Exception('QR paiement incomplet');
    }

    final int merchantId = int.parse(merchantIdRaw.toString());
    final String merchantName = merchantNameRaw?.toString() ?? 'Merchant';
    final double amount = double.parse(amountRaw.toString());

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PayPage(
          merchantId: merchantId,
          merchantName: merchantName,
          amount: amount,
        ),
      ),
    );

    if (widget.onPaymentDone != null) {
      await widget.onPaymentDone!();
    }
  }

  Future<void> _handleScan(String code) async {
    if (_isProcessing) return;
    if (code.isEmpty) {
      _showError('QR invalide');
      return;
    }

    _isProcessing = true;

    try {
      // QR eSIM
      if (code.startsWith('LPA:1\$')) {
        await _showEsimDialog(code);
        return;
      }

      // QR paiement FGPay
      final dynamic decoded = jsonDecode(code);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('QR non reconnu');
      }

      if (decoded['type'] != 'fgpay_qr') {
        throw Exception('QR pa valab pou paiement');
      }

      await _openPayPage(decoded);
    } catch (e) {
      _showError('Erreur scan: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final String? code = barcodes.first.rawValue;
              if (code == null || code.trim().isEmpty) {
                _showError('QR vide');
                return;
              }

              _handleScan(code.trim());
            },
          ),

          Positioned(
            left: 24,
            right: 24,
            bottom: 30,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Scan yon QR paiement FGPay oswa yon QR eSIM.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}