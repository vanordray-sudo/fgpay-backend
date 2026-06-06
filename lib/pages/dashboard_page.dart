import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/wallet_service.dart';
import 'login_page.dart';
import 'receipt_page.dart';
import 'qr_pay_page.dart';
import 'scan_qr_page.dart';
import 'iptv_page.dart';
import 'stripe_payment_page.dart';
import 'esim_page.dart';
import 'starlink_page.dart';
import 'main_entry_page.dart';
import 'paypal_payment_page.dart';
import 'live_tv_page.dart';
import 'internet_page.dart';
import 'my_esim_page.dart';
import 'receipt_page.dart';
import 'payment_methods_page.dart';
import 'admin_payments_page.dart';
import 'notifications_page.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'health_page.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool isLoading = true;
  int notificationCount = 0;
  Timer? _notificationTimer; 
  final AudioPlayer _audioPlayer = AudioPlayer();

  double balance = 0.0;
  List<Map<String, dynamic>> transactions = [];

  String errorMessage = '';

  String userName = '';
  String userPhone = '';
  String userEmail = '';
  String userNif = '';
  String userAddress = '';

  String selectedCurrency = 'HTG';
  final double usdRate = 132.0;
  final double eurRate = 145.0;


  double safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

 double getConvertedBalance() {
  switch (selectedCurrency) {
    case 'USD':
      return balance / 132;
    case 'EUR':
      return balance / 145;
    case 'HTG':
    default:
      return balance;
  }
}
  
  String getTransactionTitle(Map<String, dynamic> tx) {
  final type = (tx['type'] ?? '').toString().toLowerCase();
  final description = (tx['description'] ?? '').toString().trim();
  final receiver = (tx['receiver_name'] ?? tx['receiver'] ?? '').toString().trim();
  final sender = (tx['sender_name'] ?? tx['sender'] ?? '').toString().trim();

  if (description.isNotEmpty) return description;

  switch (type) {
    case 'topup':
    case 'cashin':
    case 'cash_in':
      return 'Cash In';
    case 'payment':
    case 'pay':
      return 'Payment';
    case 'transfer':
      if (receiver.isNotEmpty) return 'Transfer to $receiver';
      return 'Transfer';
    case 'received':
      if (sender.isNotEmpty) return 'Received from $sender';
      return 'Money Received';
    default:
      return 'Transaction';
  }
}

String getTransactionSubtitle(Map<String, dynamic> tx) {
  final rawDate = tx['created_at'] ?? tx['date'] ?? '';
  if (rawDate.toString().isEmpty) return 'Date indisponible';

  try {
    final date = DateTime.parse(rawDate.toString()).toLocal();
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return rawDate.toString();
  }
}

bool isPositiveTransaction(Map<String, dynamic> tx) {
  final type = (tx['type'] ?? '').toString().toLowerCase();
  return type == 'topup' ||
      type == 'cashin' ||
      type == 'cash_in' ||
      type == 'received' ||
      type == 'deposit';
}

IconData getTransactionIcon(Map<String, dynamic> tx) {
  final type = (tx['type'] ?? '').toString().toLowerCase();

 switch (type) {
  case 'topup':
  case 'cashin':
  case 'cash_in':
  case 'received':
  case 'deposit':
    return Icons.arrow_downward_rounded; // 💚 incoming

  case 'payment':
  case 'pay':
    return Icons.shopping_cart_rounded; // 🛒 paiement

  case 'transfer':
    return Icons.send_rounded; // 📤 envoi

  case 'qr':
    return Icons.qr_code_rounded; // 🔳 QR

  default:
    return Icons.receipt_long_rounded; // 🧾 fallback
}
}

Color getTransactionColor(Map<String, dynamic> tx) {
  final type = (tx['type'] ?? '').toString().toLowerCase();

  if (type.contains('cash') ||
      type.contains('deposit') ||
      type.contains('received')) {
    return Colors.green;
  }

  if (type.contains('transfer')) {
    return Colors.orange;
  }

  if (type.contains('payment') || type.contains('pay')) {
    return Colors.red;
  }

  return Colors.grey;
}

String getTransactionAmountText(Map<String, dynamic> tx) {
  final rawAmount = tx['amount'] ?? 0;
  final amount = double.tryParse(rawAmount.toString()) ?? 0.0;
  final prefix = isPositiveTransaction(tx) ? '+' : '-';
  return '$prefix${amount.toStringAsFixed(2)} HTG';
}
 
 Future<String?> _askSecurityPin() async {
  final pinController = TextEditingController();

  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('PIN Sécurité'),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
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
              final pin = pinController.text.trim();

              if (pin.isEmpty || pin.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN invalide')),
                );
                return;
              }

              Navigator.pop(context, pin);
            },
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
}
 
 Widget buildCurrencyChip(String currency) {
  final isSelected = selectedCurrency == currency;

  return GestureDetector(
    onTap: () {
      setState(() {
        selectedCurrency = currency;
      });
    },
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

void initState() {
  super.initState();
  _boot();
  startNotificationPolling();

  _initFirebase();
}

Future<void> _initFirebase() async {
  final token = await FirebaseMessaging.instance.getToken();
  print('TOKEN: $token');

  if (token != null) {
    await WalletService.saveFcmToken(token);
  }
}

Future<void> _boot() async {
  final loggedIn = await AuthService.isLoggedIn();

  if (!loggedIn) {
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
    return;
  }

  await loadData();
}

 void startNotificationPolling() {
  _notificationTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
    final count = await WalletService.getUnreadNotificationCount();

    if (!mounted) return;

    setState(() {
      notificationCount = count;
    });
  });
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

 Future<void> fetchBalance() async {
  print('CALL fetchBalance');
  final data = await WalletService.getBalance();
  print('BALANCE RESPONSE: $data');

  if (!mounted) return;

  setState(() {
    balance = data ?? balance;
  });
}

Future<void> fetchTransactions() async {
  print('CALL fetchTransactions');
  final data = await WalletService.getTransactions();
  print('TRANSACTIONS RESPONSE: $data');

  if (!mounted) return;

  setState(() {
    transactions = List<Map<String, dynamic>>.from(data);
  });
}
 
 Future<void> loadData() async {
  if (!mounted) return;

  setState(() => isLoading = true);

  try {
  final newBalance = (await WalletService.getBalance()) ?? 0.0;

final newTransactions = List<Map<String, dynamic>>.from(
  await WalletService.getTransactions(),
);
    if (!mounted) return;

    setState(() {
      balance = newBalance;
      transactions = newTransactions;
    });

  } catch (e) {
    final msg = e.toString();

    if (msg.contains('SESSION_EXPIRED') || msg.contains('Token')) {
      if (!mounted) return;

      await AuthService.logout();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      errorMessage = msg;
    });

  } finally {
    if (!mounted) return;

    setState(() => isLoading = false);
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
  await AuthService.clearSession();

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => LoginPage()),
  );
}

Future<void> showTopUpDialog() async {
  final controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Montant invalide')),
                );
                return;
              }

             final pin = await _askSecurityPin();

if (pin == null || pin.isEmpty) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Antre PIN la')),
  );
  return;
}

if (pin.length != 6) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('PIN dwe gen 4 chif')),
  );
  return;
}
              final result = await WalletService.topUp(
                amount: amount,
                pin: pin,
              );

              if (!mounted) return;

              Navigator.pop(dialogContext);

              if (result['success'] == true) {
  await loadData(); // 🔥 refresh wallet imedyatman

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result['message'] ?? 'Topup réussi 💸'),
    ),
  );
} else {
  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(result['message'] ?? 'Erreur topup ❌'),
    ),
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

              Navigator.pop(dialogContext);

              try {
                final result = await WalletService.pay(
                  amount: amount,
                  pin: '1111',
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
  data: {
    'merchantName': userName,
    'amount': amount,
    'baseAmount': result['baseAmount'] ?? amount,
    'tcaAmount': result['tcaAmount'] ?? 0,
    'fgpayCommission': result['fgpayCommission'] ?? 0,
    'totalAmount': result['totalAmount'] ?? amount,
    'reference': (result['reference'] ?? 'N/A').toString(),
    'createdAt': DateTime.now().toString(),
    'status': 'SUCCESS',
    'description': 'Transaction FGPay',
  },
)
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

Future<void> _openSubscription(String service) async {
  final pinController = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(

        title: Text('Souscrire $service'),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'PIN',
          ),
        ),
        actions: [
          TextButton(


           onPressed: () {
  Navigator.pop(context); // retounen Dashboard pou user klike Abonnement
},

            child: const Text('Annuler'),
          ),

        ElevatedButton(
  onPressed: () async {
    final pin = pinController.text.trim();

    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antre PIN la')),
      );
      return;
    }

    try {
      final result = await WalletService.subscribe(
        service: service,
        plan: 'basic',
        amount: 10,
        pin: pin,
      );


      print('SUBSCRIBE RESULT: $result');

      if (!mounted) return;
      Navigator.pop(dialogContext);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Réponse vide')),
      );
    } catch (e) {
      print('SUBSCRIBE ERROR: $e');

      if (!mounted) return;
      Navigator.pop(dialogContext);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur app: $e')),
      );
    }
  },
  child: const Text('Payer'),
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

            final pin = await _askSecurityPin();
            if (pin == null || pin.isEmpty) return;

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

                if (!mounted) return;

                final receipt = result['receipt'] ?? {};

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReceiptPage(
                      data: {
                        'merchantName': receiverPhone,
                        'amount': receipt['totalAmount'] ?? amount,
                        'baseAmount': receipt['baseAmount'] ?? amount,
                        'tcaAmount': receipt['tcaAmount'] ?? 0,
                        'commissionAmount': receipt['commissionAmount'] ?? 0,
                        'totalAmount': receipt['totalAmount'] ?? amount,
                        'reference': result['reference'] ?? 'N/A',
                        'createdAt': receipt['date'] ?? DateTime.now().toString(),
                        'status': 'SUCCESS',
                        'description': 'Transfert vers $receiverPhone',
                      },
                    ),
                  ),
                );

                await loadData();
              } else {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Erreur transfert'),
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
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
    ),
    child: Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(userName),
              Text(userEmail),
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          '${getConvertedBalance().toStringAsFixed(2)} $selectedCurrency',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

       Row(
  children: [
    buildCurrencyChip('HTG'),
    const SizedBox(width: 8),
    buildCurrencyChip('USD'),
    const SizedBox(width: 8),
    buildCurrencyChip('EUR'),
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



 Widget buildTransactionCard(Map<String, dynamic> tx) {

  final type = (tx['type'] ?? '').toString().toLowerCase();

 final amount =
  double.tryParse((tx['amount'] ?? 0).toString()) ?? 0.0;

final baseAmount =
  double.tryParse((tx['base_amount'] ?? tx['baseAmount'] ?? 0).toString()) ?? amount;

final tcaAmount =
  double.tryParse((tx['tca_amount'] ?? tx['tcaAmount'] ?? 0).toString()) ?? 0.0;

final totalAmount =
  double.tryParse((tx['total_amount'] ?? tx['totalAmount'] ?? 0).toString()) ?? amount;

  final rawDate = (tx['date'] ?? tx['created_at'] ?? '').toString();
  final direction = (tx['direction'] ?? '').toString().toLowerCase();
  final name = (tx['name'] ?? '').toString().trim();
  final titleFromApi = (tx['title'] ?? '').toString().trim();

  final bool isQrPayment = type == 'qr_payment' || type == 'qr';
  final bool isCredit =
      type == 'topup' ||
      type == 'cashin' ||
      type == 'cash_in' ||
      type == 'credit_transfer' ||
      direction == 'received';

  String title;
  if (titleFromApi.isNotEmpty) {
    title = titleFromApi;
  } else if (isQrPayment && name.isNotEmpty) {
    title = 'QR Payment - $name';
  } else if (isQrPayment) {
    title = 'QR Payment';
  } else if (type == 'topup' || type == 'cashin' || type == 'cash_in') {
    title = 'Cash In';
  } else if (type == 'payment' || type == 'pay') {
    title = 'Payment';
  } else if (type == 'transfer' && name.isNotEmpty) {
    title = 'Transfer to $name';
  } else if (direction == 'received' && name.isNotEmpty) {
    title = 'Received from $name';
  } else if (type == 'transfer') {
    title = 'Transfer';
  } else {
    title = isCredit ? 'Cash In' : 'Payment';
  }

  String subtitle = 'Date indisponible';
  if (rawDate.isNotEmpty) {
    try {
      final date = DateTime.parse(rawDate).toLocal();
      subtitle =
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}  '
          '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      subtitle = rawDate;
    }
  }

  final String amountText;
  if (isQrPayment) {
    amountText = '-${totalAmount.toStringAsFixed(2)} HTG';
  } else {
    amountText = '${isCredit ? '+' : '-'}${amount.toStringAsFixed(2)} HTG';
  }

  final String detailsText = isQrPayment
      ? 'Montant: ${baseAmount.toStringAsFixed(2)} HTG • '
        'TCA: ${tcaAmount.toStringAsFixed(2)} HTG • '
        'Total: ${totalAmount.toStringAsFixed(2)} HTG'
      : subtitle;

  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: CircleAvatar(
      backgroundColor: isCredit
          ? Colors.green.withOpacity(0.12)
          : Colors.red.withOpacity(0.12),
      child: Icon(
        isCredit ? Icons.add : Icons.qr_code_2,
        color: isCredit ? Colors.green : Colors.red,
      ),
    ),
    title: Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
      ),
    ),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        if (isQrPayment)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              detailsText,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black54,
              ),
            ),
          ),
      ],
    ),
    trailing: Text(
      amountText,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isCredit ? Colors.green : Colors.red,
      ),
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
          

          final pin = await _askSecurityPin();
if (pin == null) return;

final result = await WalletService.pay(
  amount: amount,
  description: description,
  pin: pin,
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
 
  Widget _buildServiceButton({
  required IconData icon,
  required String label,
  required String subtitle,
  required VoidCallback onTap,
  Color iconColor = Colors.blue,
  double width = 150,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: width,
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
        children: [
          Icon(icon, color: iconColor, size: 30),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    ),
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
                'Byenvini sou FGPay , Nou kontan wè ou🚀',
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
                  _buildServiceButton(
  icon: Icons.wifi,
  label: 'Internet',
  subtitle: 'Forfaits data',
  onTap: () {
    _openSubscription('internet');
  },
),

_buildServiceButton(
  icon: Icons.live_tv,
  label: 'IPTV',
  subtitle: 'TV en direct',
  onTap: () {
    _openSubscription('iptv');
  },
),

_buildServiceButton(
  icon: Icons.card_membership,
  label: 'Abonnement',
  subtitle: 'Activer IPTV',
  onTap: () {
    _openSubscription('iptv');
  },
),
                  _buildServiceButton(
                    icon: Icons.account_balance_wallet,
                    label: 'Cash In',
                    subtitle: 'Recharge wallet',
                    onTap: () async {
                      final amountController = TextEditingController();

                      final amount = await showDialog<double>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text('Cash In'),
                            content: TextField(
                              controller: amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Montant',
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
                                  final value = double.tryParse(
                                    amountController.text.trim(),
                                  );
                                  Navigator.pop(context, value);
                                },
                                child: const Text('Valider'),
                              ),
                            ],
                          );
                        },
                      );

                      if (amount == null || amount <= 0) return;

                      final pin = await _askSecurityPin();
                      if (pin == null) return;

                      final result = await WalletService.topUp(
                        amount: amount,
                        pin: pin,
                      );

                      if (!mounted) return;

                      if (result['success'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cash In réussi ✅'),
                          ),
                        );
                        await loadData();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ?? 'Erreur Cash In',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildServiceButton(
                    icon: Icons.send,
                    label: 'Send Money',
                    subtitle: 'Transfer funds',
                    onTap: showTransferDialog,
                  ),
                  _buildServiceButton(
  icon: Icons.admin_panel_settings,
  label: 'Admin',
  subtitle: 'Paiements',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminPaymentsPage(),
      ),
    );
  },
),

                  _buildServiceButton(
                    icon: Icons.payment,
                    label: 'Pay',
                    subtitle: 'Pay services',
                   onTap: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
),
                  ),
                  _buildServiceButton(
                    icon: Icons.qr_code,
                    label: 'QR Pay',
                    subtitle: 'Pay with QR',
                    onTap: openMyQr,
                  ),
                  _buildServiceButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan',
                    subtitle: 'Scan code',
                    onTap: openScanQr,
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
                  _buildServiceButton(
                    icon: Icons.account_balance,
                    label: 'PayPal',
                    subtitle: 'Online payments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PayPalPaymentPage(),
                        ),
                      );
                    },
                  ),
                  _buildServiceButton(
                    icon: Icons.credit_card,
                    label: 'Stripe',
                    subtitle: 'Card payments',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StripePaymentPage(),
                        ),
                      );
                    },
                  ),
                  _buildServiceButton(
                    icon: Icons.tv,
                    label: 'IPTV',
                    subtitle: 'TV packages',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IptvPage(),
                        ),
                      );
                    },
                  ),
                  _buildServiceButton(
                    icon: Icons.play_circle_fill,
                    label: 'LIVE TV',
                    subtitle: 'Watch live channels',
                    iconColor: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveTVPage(),
                        ),
                      );
                    },
                  ),
                  _buildServiceButton(
                    icon: Icons.sim_card,
                    label: 'eSIM',
                    subtitle: 'Mobile data plans',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EsimPage(),
                        ),
                      );
                    },
                  ),
                 
                 _buildServiceButton(
  icon: Icons.sim_card_outlined,
  label: 'Mes eSIM',
  subtitle: 'Voir mes lignes',
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyEsimPage(),
      ),
    );
  },
),


_buildServiceButton(
  icon: Icons.health_and_safety,
  label: 'FG Santé',
  subtitle: 'Dossier médical',
  iconColor: Colors.red,
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const HealthPage(),
      ),
    );
  },
),


                  _buildServiceButton(
                    icon: Icons.wifi,
                    label: 'Internet',
                    subtitle: 'Plans & Data',
                    iconColor: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InternetPage(),
                        ),
                      );
                    },
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

  Stack(
  children: [
    IconButton(
      icon: const Icon(Icons.notifications_none),
      tooltip: 'Notifications',
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotificationsPage(),
          ),
        );
      },
    ),

    if (notificationCount > 0)
      Positioned(
        right: 6,
        top: 6,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: const BoxConstraints(
            minWidth: 18,
            minHeight: 18,
          ),
          child: Text(
            '$notificationCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
  ],
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

