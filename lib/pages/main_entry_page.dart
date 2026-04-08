import 'package:flutter/material.dart';
import 'dashboard_page.dart';

class MainEntryPage extends StatelessWidget {
  const MainEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: DashboardPage(),
      ),
    );
  }
}