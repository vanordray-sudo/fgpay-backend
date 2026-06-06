import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class ReceiptPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReceiptPage({
    super.key,
    required this.data,
  });

  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  String _toText(dynamic value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget _infoTile(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value, {bool highlight = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFEAFBF2) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: highlight ? const Color(0xFFB7E4C7) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: highlight ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: highlight ? const Color(0xFF15803D) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
final receipt = data['receipt'] ?? data;
final meta = data['data'] ?? data;
 final baseAmount = _toDouble(
  receipt['baseAmount'] ?? receipt['base_amount'] ?? receipt['amount'],
);

final tcaAmount = _toDouble(
  receipt['tcaAmount'] ?? receipt['tca_amount'],
);

final fgpayCommission = _toDouble(
  receipt['commissionAmount'] ??
  receipt['fgpayCommission'] ??
  receipt['fgpay_commission'] ??
  receipt['commission'],
);

final totalAmount = _toDouble(
  receipt['totalAmount'] ?? receipt['total_amount'] ?? receipt['amount'],
);  

   final merchantName = _toText(
  meta['merchantName'] ?? meta['merchant_name'] ?? meta['receiverName'] ?? meta['receiver'],
  fallback: 'Merchant',
);

final description = _toText(
  meta['description'] ?? meta['title'],
  fallback: 'Paiement effectué avec succès',
);

final reference = _toText(
  data['reference'] ??
  meta['reference'] ??
  data['transaction']?['reference'] ??
  data['transactionId'] ??
  data['id'],
);

final createdAt = _toText(
  receipt['date'] ??
  data['createdAt'] ??
  data['created_at'] ??
  data['date'] ??
  data['transaction']?['created_at'],
  fallback: 'N/A',
);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF6F8FC),
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: const Text('Reçu FGPay'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5B6CFF), Color(0xFF2D9CFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Paiement réussi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Montant total débité',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} HTG',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _summaryBox(
                    'Base',
                    '${baseAmount.toStringAsFixed(2)} HTG',
                  ),
                  const SizedBox(width: 12),
                  _summaryBox(
                    'TCA',
                    '${tcaAmount.toStringAsFixed(2)} HTG',
                  ),
                  const SizedBox(width: 12),
                  _summaryBox(
                    'Commission',
                    '${fgpayCommission.toStringAsFixed(2)} HTG',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryBox(
                    'Total',
                    '${totalAmount.toStringAsFixed(2)} HTG',
                    highlight: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails transaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoTile('Marchand', merchantName),
                    _infoTile('Description', description),
                    _infoTile('Référence', reference),
                    _infoTile('Date', createdAt),
                    _infoTile(
                      'Statut',
                      _toText(data['status'], fallback: 'SUCCESS'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D9CFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardPage(),
                      ),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.dashboard_customize_outlined),
                  label: const Text('Retour au Dashboard'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}