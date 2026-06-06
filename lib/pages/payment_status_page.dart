import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class PaymentStatusPage extends StatefulWidget {
  const PaymentStatusPage({super.key});

  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  bool isLoading = true;
  List<dynamic> payments = [];

  @override
  void initState() {
    super.initState();
    loadPayments();
  }

 Future<void> loadPayments() async {
  setState(() {
    isLoading = true;
    payments = [];
  });

  try {
    final data = await WalletService.getManualPayments();

    print('DATA = $data');

    final loadedPayments =
        List<dynamic>.from(data['payments'] ?? []);

    print('PAYMENTS LENGTH = ${loadedPayments.length}');

    setState(() {
      payments = loadedPayments;
      isLoading = false;
    });
  } catch (e) {
    print('LOAD ERROR = $e');

    setState(() {
      isLoading = false;
    });
  }
 


  Color _statusColor(String status) {
    switch (status) {
      case 'validated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'validated':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'En attente';
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Mes paiements'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : payments.isEmpty
        ? const Center(
            child: Text('Aucun paiement trouvé'),
          )
        : ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment =
                  payments[index] as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    payment['title'] ??
                        'Paiement',
                  ),
                  subtitle: Text(
                    '${payment['amount']} HTG',
                  ),
                ),
              );
            },
          ),
    );
  }
}