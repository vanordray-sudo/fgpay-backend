import 'package:flutter/material.dart';
import 'pages/login_page.dart';
import 'pages/main_entry_page.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isLoggedIn = await AuthService.isLoggedIn();

  runApp(FGPayApp(isLoggedIn: isLoggedIn));
}

class FGPayApp extends StatelessWidget {
  final bool isLoggedIn;

  const FGPayApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FGPay',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? const MainEntryPage() : const LoginPage(),
    );
  }
}