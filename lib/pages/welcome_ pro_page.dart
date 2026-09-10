import 'package:flutter/material.dart';

class WelcomeProPage extends StatelessWidget {
  const WelcomeProPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              const Icon(
                Icons.work,
                size: 100,
                color: Colors.blue,
              ),

              const SizedBox(height: 20),

              const Text(
                'FG Missions Pro',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'La plateforme qui connecte les entreprises aux autoentrepreneurs',
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    'Je suis une entreprise',
                  ),
                ),
              ),

              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                    'Je suis autoentrepreneur',
                  ),
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Hôtellerie • Restauration • Nettoyage • Livraison • Événementiel',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}