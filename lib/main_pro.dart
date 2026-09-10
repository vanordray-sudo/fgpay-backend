import 'package:flutter/material.dart';
import 'pages/welcome_pro_page.dart';

void main() {
  runApp(const FGMissionsPro());
}

class FGMissionsPro extends StatelessWidget {
  const FGMissionsPro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FG Missions Pro',
      home: const WelcomeProPage(),
    );
  }
}
