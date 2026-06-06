import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import 'receipt_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../config/api_config.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  List<dynamic> payments = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

  Future<void> loadPayments() async {
    setState(() => isLoading = true);

    try {
      final data = await WalletService.getManualPayments();
      print(data);

      setState(() {
        isLoading = false;
      });

      print('PAYMENTS LENGTH: ${payments.length}');
    } catch (e) {
      print('Erreur chargement paiements: $e');

      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur chargement paiements: $e')),
      );
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> validatePayment(Map p) async {
    print("CLICK ID = ${p['id']}");

    final result = await WalletService.validateManualPayment(
      paymentId: p['id'],
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await loadPayments();

      if (!mounted) return;

      final receipt = result['receipt'] ?? {};

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReceiptPage(
            data: {
              'merchantName': receipt['merchantName'] ?? 'FGPay Admin',
              'amount': receipt['amount'] ?? p['amount'],
              'baseAmount': receipt['baseAmount'] ?? p['amount'],
              'tcaAmount': receipt['tcaAmount'] ?? 0,
              'commissionAmount': receipt['commissionAmount'] ?? 0,
              'totalAmount': receipt['totalAmount'] ?? p['amount'],
              'reference': receipt['reference'] ?? p['reference_manual'] ?? 'N/A',
              'createdAt': receipt['createdAt'] ?? DateTime.now().toString(),
              'status': receipt['status'] ?? 'APPROVED',
              'description': 'Recharge validée',
            },
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Paiement validé')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur serveur')),
      );
    }
  }

  Future<void> rejectPayment(Map p) async {
    final result = await WalletService.rejectManualPayment(
      paymentId: p['id'],
    );

    if (!mounted) return;

    if (result['success'] == true) {
      await loadPayments();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Paiement rejeté')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erreur')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin paiements'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : payments.isEmpty
              ? const Center(child: Text('Aucun paiement trouvé'))
              : ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index] as Map;

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const Icon(Icons.payment),
                        title: Text(payment['name'] ?? 'Utilisateur'),
                        subtitle: Text('${payment['amount']} HTG'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                             onPressed: () async {
  final result = await WalletService.validateManualPayment(
    paymentId: payment['id'],
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'] ?? 'Paiement validé')),
  );

  await loadPayments();
},
 child: const Text('Valider'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                             onPressed: () async {
  final result = await WalletService.rejectManualPayment(
    paymentId: payment['id'],
  );

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'] ?? 'Paiement rejeté')),
  );

  await loadPayments();
},
 child: const Text('Rejeter'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}