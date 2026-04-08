import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import 'login_page.dart';
import 'receipt_page.dart';
import 'qr_pay_page.dart';
import 'scan_qr_page.dart';
import 'iptv_page.dart';
import 'stripe_payment_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  double balance = 0;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  String errorMessage = '';

  String userName = '';
  String userPhone = '';
  String userEmail = '';
  String userNif = '';
  String userAddress = '';

  String selectedCurrency = 'HTG';
  final double usdRate = 132.0;
  final double eurRate = 145.0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void openMyQr() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrPayPage(
          merchantId: 3,
          merchantName: userName.isEmpty ? 'FGPay Merchant' : userName,
        ),
      ),
    );
  }

  void openScanQr() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScanQrPage(
          onPaymentDone: loadData,
        ),
      ),
    );
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final currentUser = await AuthService.getCurrentUser();
      final loadedBalance = await WalletService.getBalance();
      final loadedTransactions = await WalletService.getTransactions();

      if (!mounted) return;

      setState(() {
       userName = (currentUser['name'] ?? '').toString();
userPhone = (currentUser['phone'] ?? '').toString();
userEmail = (currentUser['email'] ?? '').toString();
userNif = (currentUser['nif'] ?? '').toString();
userAddress = (currentUser['address'] ?? '').toString();
        balance = loadedBalance;
        transactions = List<Map<String, dynamic>>.from(loadedTransactions);
        isLoading = false;
        errorMessage = '';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  double getDisplayBalance() {
    if (selectedCurrency == 'USD') {
      return balance / usdRate;
    } else if (selectedCurrency == 'EUR') {
      return balance / eurRate;
    }
    return balance;
  }

  String getCurrencySymbol() {
    if (selectedCurrency == 'USD') return 'USD';
    if (selectedCurrency == 'EUR') return 'EUR';
    return 'HTG';
  }

  Future<void> handleLogout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
Future<void> showTopUpDialog() async {
  final controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Cash In'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Montant',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());

              if (amount == null || amount <= 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tanpri antre yon montan valab'),
                  ),
                );
                return;
              }

              Navigator.pop(dialogContext);

              try {
                final result = await WalletService.topUp(amount);

                if (result['success'] == true) {
                 
                  await loadData();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Cash In réussi: +${amount.toStringAsFixed(2)} HTG',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (result['message'] ?? 'Erreur top up').toString(),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
}

Future<void> showPayDialog() async {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text('Pay'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Montant',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim());
              final description = descriptionController.text.trim();

              if (amount == null || amount <= 0) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Montant invalide')),
                );
                return;
              }

              final pinController = TextEditingController();

              final pin = await showDialog<String>(
                context: dialogContext,
                builder: (pinContext) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
                        onPressed: () => Navigator.pop(pinContext),
                        child: const Text('Annuler'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(pinContext, pinController.text.trim());
                        },
                        child: const Text('Confirmer'),
                      ),
                    ],
                  );
                },
              );

              if (pin == null || pin.isEmpty) return;

              Navigator.pop(dialogContext);

              try {
                final result = await WalletService.pay(
                  amount: amount,
                  pin: pin,
                  description: description,
                );

                if (!mounted) return;

                if (result['success'] == true) {
                  await loadData();

                  if (!mounted) return;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReceiptPage(
                        senderName: userName,
                        senderPhone: userPhone,
                        senderNif: userNif,
                        senderAddress: userAddress,
                        receiverName: 'Service Payment',
                        receiverPhone: '-',
                        amount: amount,
                        reference:
                            'PAY-${DateTime.now().millisecondsSinceEpoch}',
                        date: (result['transaction']?['date'] ?? '').toString(),
                        transactionType: 'payment',
                        description: description,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        (result['message'] ?? 'Erreur paiement').toString(),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: $e')),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
}

Future<void> showTransferDialog() async {
  final phoneController = TextEditingController();
  final amountController = TextEditingController();

  bool isSending = false;

  await showDialog(
    context: context,
    barrierDismissible: !isSending,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Future<void> sendMoney() async {
            FocusScope.of(context).unfocus();

            final receiverPhone = phoneController.text.trim();
            final amountText = amountController.text.trim();
            final amount = double.tryParse(amountText);

            if (receiverPhone.isEmpty ||
                amountText.isEmpty ||
                amount == null ||
                amount <= 0) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Tanpri ranpli nimewo destinatè ak montan an',
                  ),
                ),
              );
              return;
            }

            final pinController = TextEditingController();

            final pin = await showDialog<String>(
              context: dialogContext,
              builder: (pinContext) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
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
                      onPressed: () => Navigator.pop(pinContext),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(pinContext, pinController.text.trim());
                      },
                      child: const Text('Confirmer'),
                    ),
                  ],
                );
              },
            );

            if (pin == null || pin.isEmpty) {
              return;
            }

            setDialogState(() {
              isSending = true;
            });

            try {
              final result = await WalletService.transfer(
                receiverPhone: receiverPhone,
                amount: amount,
                pin: pin,
              );

              setDialogState(() {
                isSending = false;
              });

              if (result['success'] == true) {
                Navigator.pop(dialogContext);
                await loadData();

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptPage(
                      senderName: userName,
                      senderPhone: userPhone,
                      senderNif: userNif,
                       senderAddress: userAddress,
                      receiverName: receiverPhone,
                      receiverPhone: receiverPhone,
                      amount: amount,
                      reference: (result['reference'] ?? 'N/A').toString(),
                      date: (result['transaction']?['date'] ?? '').toString(),
                    ),
                  ),
                );
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      (result['message'] ?? 'Erreur transfert').toString(),
                    ),
                  ),
                );
              }
            } catch (e) {
              setDialogState(() {
                isSending = false;
              });

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Send Money'),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro téléphone',
                      hintText: 'Egzanp: 50922222222',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Montant',
                      hintText: 'Egzanp: 300',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSending ? null : () => Navigator.pop(dialogContext),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: isSending ? null : sendMoney,
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.3),
                      )
                    : const Text('Envoyer'),
              ),
            ],
          );
        },
      );
    },
  );
}
  Widget buildUserInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF1)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color.fromRGBO(0, 0, 0, 0.04),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF0D6EFD), Color(0xFF3FA2FF)],
              ),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isEmpty ? 'Utilisateur FGPay' : userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Téléphone: $userPhone',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  'Email: $userEmail',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${getDisplayBalance().toStringAsFixed(2)} ${getCurrencySymbol()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              _buildCurrencyChip('HTG'),
              _buildCurrencyChip('USD'),
              _buildCurrencyChip('EUR'),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Secure digital payments powered by FGPay',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(String currency) {
    final bool isSelected = selectedCurrency == currency;

    return InkWell(
      onTap: () {
        setState(() {
          selectedCurrency = currency;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          currency,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget buildTransactionCard(Map<String, dynamic> tx) {
    final type = (tx['type'] ?? '').toString().toLowerCase();
    final amountValue = tx['amount'];
    final amountText = amountValue == null ? '0.00' : amountValue.toString();

    final rawDate = (tx['date'] ?? tx['created_at'] ?? '').toString();
    final direction = (tx['direction'] ?? '').toString().toLowerCase();
    final name = (tx['name'] ?? '').toString();
    final titleFromApi = (tx['title'] ?? '').toString();

    final bool isCredit =
        type == 'topup' || type == 'credit_transfer' || direction == 'received';

    String title;
    if (titleFromApi.isNotEmpty) {
      title = titleFromApi;
    } else if (type == 'topup') {
      title = 'Cash In';
    } else if (type == 'payment') {
      title = 'Payment';
    } else if (direction == 'received') {
      title = name.isNotEmpty ? 'Received from $name' : 'Received Money';
    } else if (type == 'transfer') {
      title = name.isNotEmpty ? 'Send Money to $name' : 'Send Money';
    } else {
      title = 'Transaction';
    }

    String formattedDate = rawDate;
    if (rawDate.contains('T')) {
      formattedDate = rawDate.split('T').first;
    } else if (rawDate.contains(' ')) {
      formattedDate = rawDate.split(' ').first;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            width: 46,
            height: 46,
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
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}$amountText HTG',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isCredit ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

 // 👇 METE SA NAN CLASS LA, MEN DEYÒ build()

Widget _buildPayDialog() {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  final pinController = TextEditingController();

  return AlertDialog(
    title: const Text('Pay'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: descriptionController,
          decoration: const InputDecoration(labelText: 'Description'),
        ),
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Montant'),
        ),
        TextField(
          controller: pinController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'PIN'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Annuler'),
      ),
      ElevatedButton(
        onPressed: () async {
          final amount = double.tryParse(amountController.text) ?? 0;
          final description = descriptionController.text.trim();
          final pin = pinController.text.trim();

          final result = await WalletService.pay(
            amount: amount,
            pin: pin,
            description: description,
          );

          if (!context.mounted) return;

          Navigator.pop(context);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );

          if (result['success'] == true) {
            loadData();
          }
        },
        child: const Text('Payer'),
      ),
    ],
  );
}
 
  Widget buildDashboardContent() {
    return Padding(
      padding: const EdgeInsets.all(22),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bienvenue sou FGPay 🚀',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your secure digital payment dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 20),

                buildUserInfoCard(),
                const SizedBox(height: 20),

                buildBalanceCard(),
                const SizedBox(height: 20),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  alignment: WrapAlignment.start,
                  children: [
                    InkWell(
                      onTap: showTopUpDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'Cash In',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Recharge wallet',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: showTransferDialog,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.send, color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'Send Money',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Transfer funds',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

     InkWell(
  onTap: () {
    showDialog(
      context: context,
      builder: (_) => _buildPayDialog(),
    );
  },
  borderRadius: BorderRadius.circular(16),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(Icons.payment, color: Colors.blue, size: 30),
        SizedBox(height: 10),
        Text(
          "Pay",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 6),
        Text(
          "Pay services",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  ),
),
                    InkWell(
                      onTap: openMyQr,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.qr_code, color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'QR Pay',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Pay with QR',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: openScanQr,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.qr_code_scanner,
                                color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'Scan',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Scan code',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'FG Services connectés',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PayPal bientôt disponible'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.account_balance,
                                color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'PayPal',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Online payments',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StripePaymentPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.credit_card,
                                color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'Stripe',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Card payments',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IptvPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.tv, color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'IPTV',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Live TV & VOD',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('eSIM bientôt disponible'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.sim_card,
                                color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'eSIM',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Mobile data plans',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Starlink bientôt disponible'),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 150,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 6,
                              offset: Offset(0, 2),
                              color: Color(0x14000000),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.wifi, color: Colors.blue, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'Starlink',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'High-speed internet',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Track your latest payment activity',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                if (transactions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text('Pa gen tranzaksyon'),
                    ),
                  )
                else
                  ...transactions.map((tx) => buildTransactionCard(tx)).toList(),
              ],
            ),
          ),
        ),
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
          'FGPay Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: loadData,
                          child: const Text('Recharger'),
                        ),
                      ],
                    ),
                  ),
                )
              : buildDashboardContent(),
    );
  }
}