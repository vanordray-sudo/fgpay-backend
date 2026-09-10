import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/subscription_success_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const FGSanteApp());
}

class FGSanteApp extends StatelessWidget {
  const FGSanteApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
  debugShowCheckedModeBanner: false,
  title: 'FG Santé',

  theme: ThemeData(
    useMaterial3: true,
  ),

  onGenerateRoute: (settings) {
    final uri = Uri.parse(
      settings.name ?? '/',
    );

    if (uri.path == '/subscription-success') {
      final sessionId =
          uri.queryParameters['session_id'];

      if (sessionId != null &&
          sessionId.isNotEmpty) {
        return MaterialPageRoute(
          builder: (context) =>
              SubscriptionSuccessPage(
            sessionId: sessionId,
          ),
        );
      }
    }

    return null;
  },

  home: const LoginPage(),
);
  }
}