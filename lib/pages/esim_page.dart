import 'package:flutter/material.dart';
import '../services/esim_service.dart';

class EsimPage extends StatelessWidget {
  const EsimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acheter eSIM')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await EsimService.buyEsim(
              amount: 200,
              plan: '5GB Haiti',
            );

            if (result['success'] == true) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('eSIM acheté avec succès')),
                );
              }

              Navigator.pop(context, true);
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'Erreur achat eSIM'),
                  ),
                );
              }
            }
          },
          child: const Text('Acheter eSIM (200 HTG)'),
        ),
      ),
    );
  }
}