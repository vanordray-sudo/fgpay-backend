import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/professional_service.dart';
import '../services/auth_service.dart';

class ValidationProfessionalsPage extends StatefulWidget {
  const ValidationProfessionalsPage({super.key});

  @override
  State<ValidationProfessionalsPage> createState() =>
      _ValidationProfessionalsPageState();
}

class _ValidationProfessionalsPageState
    extends State<ValidationProfessionalsPage> {

  List professionals = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfessionals();
  }
Future<void> loadProfessionals() async {
  try {
    final token = await AuthService.getToken();

    final response = await http.get(
      Uri.parse(
        'https://fgpay-backend-production.up.railway.app/api/health/professionals/pending',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    print('LOAD STATUS = ${response.statusCode}');
    print('LOAD BODY = ${response.body}');

    final data = jsonDecode(response.body);

    setState(() {
      professionals = data['professionals'] ?? [];
      loading = false;
    });
  } catch (e) {
    print(e);
    setState(() {
      loading = false;
    });
  }
}
  
Future<void> approveProfessional(int id) async {
  final response = await ProfessionalService.approveProfessional(id);

  print('APPROVE STATUS = ${response.statusCode}');
  print('APPROVE BODY = ${response.body}');

  if (response.statusCode == 200) {
    await loadProfessionals();
  }
}
Future<void> rejectProfessional(int id) async {
  Uri.parse(
'https://fgpay-backend-production.up.railway.app/api/health/professionals/pending',
);

  final response = await http.put(
    Uri.parse(
  'https://fgpay-backend-production.up.railway.app/api/health/professionals/$id/reject',
),
  );

  if (response.statusCode == 200) {
    await loadProfessionals();
  }
}
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Validation Professionnels',
        ),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: professionals.length,
              itemBuilder: (context, index) {

                final prof = professionals[index];

                return Card(
                  margin: const EdgeInsets.all(10),

                  child: ListTile(
                    title: Text(
                      prof['name'] ?? '',
                    ),

                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          prof['phone'] ?? '',
                        ),
                        Text(
                          prof['email'] ?? '',
                        ),
                      ],
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        IconButton(
  icon: const Icon(Icons.check_circle, color: Colors.green),
 onPressed: () async {
  print('CLICK APPROVE ID = ${prof['id']}');

  final response =
      await ProfessionalService.approveProfessional(prof['id']);

  print('APPROVE STATUS = ${response.statusCode}');
  print('APPROVE BODY = ${response.body}');

  await loadProfessionals();
},
),


IconButton(
  icon: const Icon(Icons.cancel, color: Colors.red),
  onPressed: () async {
    final response =
        await ProfessionalService.rejectProfessional(prof['id']);

    print('REJECT STATUS = ${response.statusCode}');
    print('REJECT BODY = ${response.body}');

    await loadProfessionals();
  },
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