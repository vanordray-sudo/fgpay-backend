import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await WalletService.getTransactions();

      if (!mounted) return;

      setState(() {
        transactions = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  String formatDate(String rawDate) {
    if (rawDate.isEmpty) return 'N/A';
    
if (reference.isNotEmpty)
  Text(
    reference,
    style: const TextStyle(
      fontSize: 11,
      color: Colors.black38,
    ),
  ),

    try {
      final dt = DateTime.parse(rawDate).toLocal();

      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year} - '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return rawDate;
    }
  }

  Widget buildTransactionCard(Map<String, dynamic> tx) {
   final type = (tx['type'] ?? '').toString();
final amount = (tx['totalAmount'] ?? tx['total_amount'] ?? tx['amount'] ?? 0).toString();
final rawDate = (tx['date'] ?? tx['created_at'] ?? '').toString();
final name = (tx['name'] ?? tx['receiver_name'] ?? tx['sender_name'] ?? '').toString();
final reference = (tx['reference'] ?? '').toString();

    final isCredit = type == 'topup' || type == 'credit_transfer';

    String title;

    if (type == 'topup') {
      title = 'Cash In';
    } else if (type == 'transfer') {
      title = name.isNotEmpty ? 'Send to $name' : 'Send Money';
    } else if (type == 'credit_transfer') {
      title = name.isNotEmpty ? 'Received from $name' : 'Received';
    } else {
      title = 'Transaction';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color.fromRGBO(0, 0, 0, 0.03),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isCredit
                  ? const Color(0xFFE8F8EE)
                  : const Color(0xFFFFECEC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatDate(rawDate),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}$amount HTG',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isCredit
                      ? const Color(0xFFE8F8EE)
                      : const Color(0xFFFFECEC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCredit ? 'Credit' : 'Debit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isCredit ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (transactions.isEmpty) {
      return const Center(
        child: Text('Pa gen tranzaksyon'),
      );
    }

    return RefreshIndicator(
      onRefresh: loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          return buildTransactionCard(transactions[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          'Transactions',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadTransactions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      body: buildBody(),
    );
  }
}