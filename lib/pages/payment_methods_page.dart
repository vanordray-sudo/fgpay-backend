import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import 'payment_status_page.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final amountController = TextEditingController();
  final referenceController = TextEditingController();

  @override
  void dispose() {
    amountController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  Future<String?> _askSecurityPin() async {
    final pinController = TextEditingController();

    final pin = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('PIN Sécurité'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'PIN'),
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

    pinController.dispose();
    return pin;
  }

  void _showManualPaymentDialog(
    BuildContext context, {
    required String method,
    required String number,
  }) {
    amountController.clear();
    referenceController.clear();

    showDialog(
  context: context,
  builder: (dialogContext) {
    return AlertDialog(
      title: Text('Paiement $method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Envoyez le paiement sur ce numéro :'),
          const SizedBox(height: 8),

          SelectableText(
            number,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Montant',
            ),
          ),

          const SizedBox(height: 10),

          TextField(
            controller: referenceController,
            decoration: const InputDecoration(
              labelText:
                  'Référence MonCash / NatCash (optionnel)',
            ),
          ),
        ],
      ),

      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop(dialogContext),
          child: const Text('Annuler'),
        ),

               ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(
                  amountController.text.trim(),
                ) ??
                0.0;

            if (amount <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Montant invalide'),
                ),
              );
              return;
            }

            final result =
                await WalletService.manualTopup(
              amount: amount,
              method: 'moncash',
            );

            if (!mounted) return;

            Navigator.pop(dialogContext);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ??
                      'Wallet crédité',
                ),
              ),
            );
          },
          child: const Text('Soumettre'),
        ),
      ],
    );
  },
);
}

Widget _buildMethod({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
          ),
        ],
      ),
    ),
  );
}
  Widget _buildStatusCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FACFE), Color(0xFF00F2FE)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suivi des paiements',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Voir vos demandes',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PaymentStatusPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Méthodes de paiement'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Choisissez une méthode de paiement',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pour MonCash, NatCash et Cash Agent, le paiement sera validé après vérification.',
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),

          _buildStatusCard(context),

          _buildMethod(
            icon: Icons.phone_android,
            title: 'MonCash',
            subtitle: 'Paiement mobile Haïti',
            onTap: () {
              _showManualPaymentDialog(
                context,
                method: 'MonCash',
                number: '+509 0000 0000',
              );
            },
          ),

          _buildMethod(
            icon: Icons.account_balance_wallet,
            title: 'NatCash',
            subtitle: 'Paiement mobile Haïti',
            onTap: () {
              _showManualPaymentDialog(
                context,
                method: 'NatCash',
                number: '+509 0000 0000',
              );
            },
          ),

          _buildMethod(
            icon: Icons.store,
            title: 'Agent FGCONNECT / Cash',
            subtitle: 'Payer chez un agent local',
            onTap: () {
              _showManualPaymentDialog(
                context,
                method: 'Cash Agent',
                number: 'Agent FGCONNECT le plus proche',
              );
            },
          ),

          _buildMethod(
            icon: Icons.credit_card,
            title: 'Carte bancaire / Stripe',
            subtitle: 'Visa, Mastercard, Amex',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stripe bientôt connecté')),
              );
            },
          ),

          _buildMethod(
            icon: Icons.payment,
            title: 'PayPal',
            subtitle: 'Paiement international',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PayPal bientôt connecté')),
              );
            },
          ),

          _buildMethod(
            icon: Icons.qr_code,
            title: 'QR Pay FGPay',
            subtitle: 'Payer avec QR code',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('QR Pay déjà disponible')),
              );
            },
          ),
        ],
      ),
    );
  }
}
