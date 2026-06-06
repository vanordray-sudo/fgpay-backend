import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import 'receipt_page.dart';
import '../services/auth_service.dart';

class PayPage extends StatefulWidget {
  final int merchantId;
  final String merchantName;
  final double amount;

  const PayPage({
    super.key,
    required this.merchantId,
    required this.merchantName,
    required this.amount,
  });

  @override
  State<PayPage> createState() => _PayPageState();
}

class _PayPageState extends State<PayPage> {
  bool _isLoading = false;
  String _errorMessage = '';

  double get _tca => widget.amount * 0.10;
  double get _fgpayCommission => widget.amount * 0.02;
  double get _total => widget.amount + _tca + _fgpayCommission;

  Future<String?> _askSecurityPin() async {
    final pinController = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('PIN Sécurité'),
          content: TextField(
            controller: pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: const InputDecoration(
              hintText: 'Entrez votre PIN',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, pinController.text.trim());
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
  }

 Future<void> _payNow() async {
  final pin = await _askSecurityPin();
  if (pin == null || pin.isEmpty) return;

  if (pin.length != 4) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN dwe gen 4 chif')),
    );
    return;
  }

  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    // 🔥 1. GET BALANCE (MAP → DOUBLE)
    final balanceData = await WalletService.getBalance();
    final currentBalance = double.tryParse(
          balanceData.toString()
        ) ??
        0.0;

    if (_total > currentBalance) {
      setState(() {
        _errorMessage = 'Solde insuffisant';
      });
      return;
    }

    final newBalance = currentBalance - _total;

    // 🔥 2. FAKE SUCCESS (PA MANYEN BACKEND)
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ReceiptPage(
          data: {
            'success': true,
            'amount': widget.amount,
            'base_amount': widget.amount,
            'tca_amount': _tca,
            'fgpay_commission': _fgpayCommission,
            'total_amount': _total,
            'merchant': widget.merchantName,
            'reference': 'QR-${DateTime.now().millisecondsSinceEpoch}',
            'message': 'Paiement QR réussi',
          },
        ),
      ),
    );
  } catch (e) {
    setState(() {
      _errorMessage = 'Erreur paiement: $e';
    });
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
  Widget _miniBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiement QR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF2D9CFF)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Paiement marchand',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.merchantName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${widget.amount.toStringAsFixed(2)} HTG',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _miniBox('Merchant ID', widget.merchantId.toString()),
                const SizedBox(width: 12),
                _miniBox('Montant', '${widget.amount.toStringAsFixed(2)} HTG'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniBox('TCA', '${_tca.toStringAsFixed(2)} HTG'),
                const SizedBox(width: 12),
                _miniBox(
                  'Commission',
                  '${_fgpayCommission.toStringAsFixed(2)} HTG',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(
                'Total à débiter: ${_total.toStringAsFixed(2)} HTG',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (_errorMessage.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _payNow,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    _isLoading ? 'Traitement...' : 'Payer maintenant',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}