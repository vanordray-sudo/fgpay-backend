import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class StarlinkPage extends StatefulWidget {
  const StarlinkPage({super.key});

  @override
  State<StarlinkPage> createState() => _StarlinkPageState();
}

class _StarlinkPageState extends State<StarlinkPage> {
  final List<Map<String, dynamic>> plans = [
    {
      'name': 'Plan Maison',
      'price': 50.99,
      'description':
          'Pou kay, WhatsApp, YouTube, navigasyon ak travay sou entènèt.',
      'speed': 'Haut débit',
      'data': '150 GB',
      'icon': Icons.home_rounded,
    },
    {
      'name': 'Plan Famille',
      'price': 70.99,
      'description':
          'Pou plizyè aparèy, videyo, apèl ak itilizasyon chak jou.',
      'speed': 'Très haut débit',
      'data': '250 GB',
      'icon': Icons.people_alt_rounded,
    },
    {
      'name': 'Plan Business',
      'price': 149.99,
      'description':
          'Pou biznis, cybercafé, biwo ak sèvis pwofesyonèl.',
      'speed': 'Prioritaire',
      'data': '350 GB',
      'icon': Icons.business_center_rounded,
    },
  ];

 Future<void> buyPlan(Map<String, dynamic> plan) async {
  final double amount = (plan['price'] as num).toDouble();
  final pinController = TextEditingController();

  final pin = await showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Confirmation achat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Achte ${plan['name']} pou \$${amount.toStringAsFixed(2)} ?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Entrez votre PIN',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext, pinController.text.trim());
            },
            child: const Text('Confirmer'),
          ),
        ],
      );
    },
  );

  if (pin == null || pin.isEmpty) return;

  if (pin.length < 4) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PIN invalide'),
      ),
    );
    return;
  }

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Paiement en cours...'),
    ),
  );

  final result = await WalletService.pay(
  amount: amount,
  pin: pin,
  description: 'Achat Starlink - ${plan['name']}',
);

  if (!mounted) return;

  if (result['success'] == true) {
    final balance = result['balance'];
    final reference = result['reference'];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Achat ${plan['name']} réussi ✅'
          '${reference != null ? ' | Réf: $reference' : ''}'
          '${balance != null ? ' | Solde: $balance' : ''}',
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Erreur paiement ❌'),
      ),
    );
  }
}
  Widget buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget buildPlanCard(Map<String, dynamic> plan) {
    final double price = (plan['price'] as num).toDouble();
    final IconData icon = plan['icon'] as IconData;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(icon, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    plan['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              plan['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            buildInfoRow(Icons.speed_rounded, 'Vitesse', plan['speed']),
            buildInfoRow(Icons.wifi_rounded, 'Données', plan['data']),
            const SizedBox(height: 10),
            Text(
              'Prix: \$${price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => buyPlan(plan),
                child: const Text(
                  'Acheter / Activer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        title: const Text('Starlink'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              'Choisissez votre offre Starlink',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sélectionnez le plan qui correspond à votre besoin.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 20),
            ...plans.map(buildPlanCard),
          ],
        ),
      ),
    );
  }
}