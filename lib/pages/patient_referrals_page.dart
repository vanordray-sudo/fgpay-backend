import 'package:flutter/material.dart';
import '../services/referral_service.dart';

class PatientReferralsPage extends StatefulWidget {
  const PatientReferralsPage({super.key});

  @override
  State<PatientReferralsPage> createState() => _PatientReferralsPageState();
}

class _PatientReferralsPageState extends State<PatientReferralsPage> {
  bool isLoading = true;
  List referrals = [];

  @override
  void initState() {
    super.initState();
    loadReferrals();
  }

  Future<void> loadReferrals() async {
    try {
      final data = await ReferralService.getPatientReferrals();

      if (!mounted) return;

      setState(() {
        referrals = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      debugPrint('PATIENT REFERRALS ERROR: $e');
    }
  }

  Color getStatusColor(dynamic status) {
    final value = (status ?? 'pending').toString().toLowerCase();

    switch (value) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes références'),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : referrals.isEmpty
              ? const Center(
                  child: Text('Aucune référence'),
                )
              : ListView.builder(
                  itemCount: referrals.length,
                  itemBuilder: (context, index) {
                    final referral = referrals[index];

                    final status =
                        (referral['status'] ?? 'pending').toString();

                    final specialty =
                        referral['specialty_name'] ??
                        referral['specialty'] ??
                        referral['specialty_name_fr'] ??
                        referral['name'] ??
                        'Spécialité non renseignée';

                    return GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Référence sélectionnée'),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        referral['doctor'] ??
                                            referral['doctor_name'] ??
                                            referral['doctor_full_name'] ??
                                            'Médecin',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(specialty.toString()),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status)
                                          .withOpacity(0.2),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: getStatusColor(status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 15),
                              Text(referral['reason'] ?? ''),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}