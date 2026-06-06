import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/esim_service.dart';
import 'my_esim_page.dart';

class EsimPage extends StatefulWidget {
  const EsimPage({super.key});

  @override
  State<EsimPage> createState() => _EsimPageState();
}

class _EsimPageState extends State<EsimPage> {
  final EsimService _esimService = EsimService();

  bool isLoading = true;
  bool isBuying = false;
  String errorMessage = '';
  List<dynamic> plans = [];

  @override
  void initState() {
    super.initState();
    loadPlans();
  }

  Future<void> loadPlans() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final result = await _esimService.fetchPlans();

      if (!mounted) return;

      setState(() {
        plans = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String?> _askPin() async {
    final pinController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('PIN sécurité'),
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
              onPressed: () {
                Navigator.pop(context, pinController.text.trim());
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
  }

 Future<void> buyPlan(Map<String, dynamic> plan) async {
  final pin = await _askPin();
  if (pin == null || pin.isEmpty) return;

  if (pin.length != 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN dwe gen 6 chif')),
    );
    return;
  }

  setState(() {
    isBuying = true;
  });

  try {
    final result = await _esimService.purchase(
      planId: int.parse(plan['id'].toString()),
      pin: pin,
    );

    if (!mounted) return;

    final esim = result['esim'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text('eSIM achetée ✅'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'Achat réussi'),
                const SizedBox(height: 16),
                Text(
                  'Plan: ${plan['name'] ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (esim != null) ...[
                  SelectableText('ICCID: ${esim['iccid'] ?? ''}'),
                  const SizedBox(height: 8),
                  SelectableText(
                    'Activation Code: ${esim['activationCode'] ?? ''}',
                  ),
                  const SizedBox(height: 8),
                  SelectableText('QR / LPA: ${esim['qrCode'] ?? ''}'),
                ],
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur achat eSIM: $e')),
    );
  } finally {
    if (!mounted) return;

    setState(() {
      isBuying = false;
    });
  }
}

Widget buildPlanCard(Map<String, dynamic> plan) {
  final name = (plan['name'] ?? 'Plan eSIM').toString();
  final country = (plan['country'] ?? '').toString();
  final dataLabel = (plan['data_label'] ?? '').toString();
  final validity = (plan['validity_days'] ?? '').toString();
  final description = (plan['description'] ?? '').toString();
  final price = (plan['price'] ?? '0').toString();
  final currency = (plan['currency'] ?? 'USD').toString();

  return Card(
    elevation: 2,
    margin: const EdgeInsets.only(bottom: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (country.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              country,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _miniBox('Data', dataLabel)),
              const SizedBox(width: 10),
              Expanded(child: _miniBox('Validité', '$validity jours')),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            '$price $currency',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isBuying ? null : () => buyPlan(plan),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(isBuying ? 'Traitement...' : 'Acheter'),
            ),
          ),
        ],
      ),
    ),
  );
}
  Widget _miniBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('eSIM'),
  actions: [
    IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyEsimPage(),
          ),
        );
      },
      icon: const Icon(Icons.list_alt),
      tooltip: 'Mes eSIM',
    ),
  ],
),
      body: RefreshIndicator(
        onRefresh: loadPlans,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF2D9CDB)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connecte-vous partout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Achetez une eSIM en quelques secondes et activez-la avec un QR code.',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Plans disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (plans.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text('Pa gen plan eSIM disponib pou kounye a.'),
              )
            else
              ...plans.map((e) => buildPlanCard(Map<String, dynamic>.from(e))),
          ],
        ),
      ),
    );
  }
}