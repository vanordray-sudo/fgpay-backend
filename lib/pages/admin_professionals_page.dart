import 'package:flutter/material.dart';
import '../services/admin_professional_service.dart';

class AdminProfessionalsPage extends StatefulWidget {
  const AdminProfessionalsPage({super.key});

  @override
  State<AdminProfessionalsPage> createState() =>
      _AdminProfessionalsPageState();
}

class _AdminProfessionalsPageState
    extends State<AdminProfessionalsPage> {

  List professionals = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfessionals();
  }

  Future<void> loadProfessionals() async {
  try {
    final result =
        await AdminProfessionalService.getPendingProfessionals();

    if (!mounted) return;

    setState(() {
      professionals = result;
      isLoading = false;
    });
  } catch (e) {
    print('LOAD PROFESSIONALS ERROR: $e');

    if (!mounted) return;

    setState(() {
      professionals = [];
      isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur chargement: $e'),
      ),
    );
  }
}

  Future<void> approve(int id) async {

    final success =
        await AdminProfessionalService
            .approveProfessional(id);

    if (success) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professionnel approuvé'),
        ),
      );

      loadProfessionals();
    }
  }

  Future<void> reject(int id) async {

    final success =
        await AdminProfessionalService
            .rejectProfessional(id);

    if (success) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Professionnel rejeté'),
        ),
      );

      loadProfessionals();
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Professionnels en attente',
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )

          : professionals.isEmpty

              ? const Center(
                  child: Text(
                    'Aucun professionnel en attente',
                  ),
                )

              : ListView.builder(
                  itemCount: professionals.length,

                  itemBuilder: (context, index) {

                    final pro = professionals[index];

                    return Card(
                      margin: const EdgeInsets.all(12),

                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            Text(
                              pro['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              pro['email'] ?? '',
                            ),

                            const SizedBox(height: 4),

                            Text(
                              pro['phone'] ?? '',
                            ),

                            const SizedBox(height: 20),

                            Row(
                              children: [

                                Expanded(
                                  child: ElevatedButton(
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.green,
                                    ),

                                    onPressed: () {
                                      approve(pro['id']);
                                    },

                                    child: const Text(
                                      'Approuver',
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                Expanded(
                                  child: ElevatedButton(
                                    style:
                                        ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.red,
                                    ),

                                    onPressed: () {
                                      reject(pro['id']);
                                    },

                                    child: const Text(
                                      'Rejeter',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}