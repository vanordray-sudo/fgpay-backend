import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/main_entry_page.dart';
import 'services/auth_service.dart';
import 'pages/payment_success_page.dart';
import 'package:flutter/foundation.dart'; // pou kIsWeb
import 'pages/paypal_payment_page.dart';
import 'pages/paypal_success_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 INIT FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔔 DEMANDE PERMISSION NOTIFICATION
  await FirebaseMessaging.instance.requestPermission();

  final isLoggedIn = await AuthService.isLoggedIn();

  runApp(FGPayApp(isLoggedIn: isLoggedIn));
}

class FGPayApp extends StatelessWidget {
  final bool isLoggedIn;

  const FGPayApp({super.key, required this.isLoggedIn});

 @override
Widget build(BuildContext context) {
  Widget homePage =
      isLoggedIn ? const MainEntryPage() : const LoginPage();

  if (kIsWeb) {
    final uri = Uri.base;
    final hash = uri.fragment;

    if (kIsWeb) {
  debugPrint('Video pa sipòte sou web');
}

    if (hash.startsWith('/payment-success')) {
      final successUri = Uri.parse(hash.replaceFirst('/', ''));
      final sessionId = successUri.queryParameters['session_id'];

      if (sessionId != null && sessionId.isNotEmpty) {
        homePage = PaymentSuccessPage(sessionId: sessionId);
      }
    }

    if (hash.startsWith('/paypal-success')) {
      final paypalUri = Uri.parse(hash.replaceFirst('/', ''));
      final orderId = paypalUri.queryParameters['token'];

      if (orderId != null && orderId.isNotEmpty) {
        homePage = PayPalSuccessPage(orderId: orderId);
      }
    }
  }


  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'FGPay',
    home: homePage,
    routes: {
      '/paypal-payment': (context) => const PayPalPaymentPage(),
    },
  );
}
} 