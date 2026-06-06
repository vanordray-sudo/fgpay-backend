import 'package:flutter/material.dart';
import '../services/admin_professional_service.dart';

class AdminProfessionalValidationPage
extends StatefulWidget{

const AdminProfessionalValidationPage({
super.key
});

@override
State<AdminProfessionalValidationPage>
createState() =>
_AdminProfessionalValidationPageState();

}

class _AdminProfessionalValidationPageState
extends State<AdminProfessionalValidationPage>{

List professionals = [];

@override
void initState() {
  super.initState();
  loadData();
}



Future<void> loadData() async {
  final data =
      await AdminProfessionalService.getPendingProfessionals();

  setState(() {
    professionals = data;
  });
}

Future<void> approve(int id) async {
  final success =
      await AdminProfessionalService.approveProfessional(id);

  if (success) {
    await loadData();
  }
}

Future<void> reject(int id) async {
  final success =
      await AdminProfessionalService.rejectProfessional(id);

  if (success) {
    await loadData();
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Validation FG Santé'),
    ),
    body: professionals.isEmpty
    ? const Center(
        child: Text(
          'Pa gen pwofil an atant',
          style: TextStyle(fontSize: 18),
        ),
      )
    : ListView.builder(
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          final pro = professionals[index];

          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text(pro['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spécialité: ${pro['specialty'] ?? ''}',
                  ),
                  Text(
                    'Téléphone: ${pro['phone'] ?? ''}',
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                    onPressed: () {
                      approve(pro['id']);
                    },
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      reject(pro['id']);
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