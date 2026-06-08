import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fgpay_clean/services/referral_service.dart';
import '../services/appointment_service.dart';
import '../../services/referral_service.dart';
import 'secretary_create_appointment_page.dart';

class DoctorReferralsPage extends StatefulWidget {
  const DoctorReferralsPage({super.key});

  @override
  State<DoctorReferralsPage> createState() =>
      _DoctorReferralsPageState();
}

class _DoctorReferralsPageState
    extends State<DoctorReferralsPage> {
  List referrals = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadReferrals();
  }

  Future<void> loadReferrals() async {
    setState(() {
      isLoading = true;
    });

    final result =
        await ReferralService.getDoctorReferrals();

    setState(() {
      referrals = result;
      isLoading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.green;

      case 'rejected':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  Future<void> updateStatus(
    int referralId,
    String status,
  ) async {
    final result =
        await ReferralService.updateStatus(
      referralId: referralId,
      status: status,
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Referral $status',
          ),
        ),
      );

      loadReferrals();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ??
                'Erreur serveur',
          ),
        ),
      );
    }
  }
Future<void> showAppointmentDialog(dynamic referral) async {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  await showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setModalState) {
          return AlertDialog(
            title: const Text('Créer rendez-vous'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );

                    if (picked != null) {
                      setModalState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                    selectedDate == null
                        ? 'Choisir date'
                        : selectedDate!.toString().split(' ')[0],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: dialogContext,
                      initialTime: TimeOfDay.now(),
                    );

                    if (picked != null) {
                      setModalState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    selectedTime == null
                        ? 'Choisir heure'
                        : selectedTime!.format(dialogContext),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate == null || selectedTime == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Choisissez une date et une heure'),
                      ),
                    );
                    return;
                  }

                  try {
                    final doctorId =
                        referral['doctor_id'] ?? referral['from_doctor_id'] ?? 3;
                    final referralId = referral['id'];

                    if (referralId == null) {
                      throw Exception('referral id manke');
                    }


print('====================');
print(referral);
print('PATIENT_ID = ${referral['patient_id']}');
print('PATIENTID = ${referral['patientId']}');
print('====================');
   final result = await AppointmentService.createAppointment(
                    
  patientId: int.parse(
    (referral['patient_id'] ?? referral['patientId']).toString(),
  ),
  doctorId: int.parse(
    (referral['to_doctor_id'] ??
            referral['doctor_id'] ??
            referral['toDoctorId'])
        .toString(),
  ),
  date: referral['appointment_date'].toString(),
  time: referral['appointment_time'].toString(),
  reason: referral['reason']?.toString() ?? '',
  referralId: int.parse(
  (referral['referral_id'] ?? referral['id']).toString(),
),
);

                    print('APPOINTMENT RESULT: $result');

                    if (!mounted) return;

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Rendez-vous créé avec succès'),
                      ),
                    );
                  } catch (e) {
                    print('APPOINTMENT ERROR: $e');

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Créer'),
  ),
            ],
          );
},
      );
    },
  );
}
Widget buildReferralCard(dynamic referral) {
  final status = referral['status'] ?? 'pending';

  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          blurRadius: 10,
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referral['patient'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      referral['specialty'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
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

          const SizedBox(height: 18),

          Text(
            referral['reason'] ?? '',
            style: const TextStyle(fontSize: 15),
          ),

          const SizedBox(height: 20),

          if (status == 'accepted')
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
          onPressed: () {
 
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SecretaryCreateAppointmentPage(
        referral: referral,
      ),
    ),
  );
},
              icon: const Icon(Icons.calendar_month),
              label: const Text('Fixer un rendez-vous'),
            ),

          if (status == 'pending')
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await ReferralService.updateReferralStatus(
                        referralId: referral['id'],
                        status: 'accepted',
                      );

                      await loadReferrals();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Référence acceptée'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur acceptation: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Accept'),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    try {
                      await ReferralService.updateReferralStatus(
                        referralId: referral['id'],
                        status: 'rejected',
                      );

                      await loadReferrals();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Référence rejetée'),
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur rejet: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text('Reject'),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FB),

      appBar: AppBar(
        title:
            const Text('Doctor Referrals'),
        backgroundColor: Colors.blue,
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : referrals.isEmpty
              ? const Center(
                  child: Text(
                    'No referrals found',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: loadReferrals,
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.all(
                      16,
                    ),
                    itemCount:
                        referrals.length,
                    itemBuilder:
                        (context, index) {
                      return buildReferralCard(
                        referrals[index],
                      );
                    },
                  ),
                ),
    );
  }
}