import 'package:flutter/material.dart';

class ProfessionalPendingPage extends StatelessWidget {
  const ProfessionalPendingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation en attente')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Votre profil professionnel est en cours de validation par FG Santé.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}