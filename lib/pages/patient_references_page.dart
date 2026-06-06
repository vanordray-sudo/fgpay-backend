import 'package:flutter/material.dart';
import '../services/referral_service.dart';

class PatientReferencesPage extends StatefulWidget {
  const PatientReferencesPage({super.key});

  @override
  State<PatientReferencesPage> createState() =>
      _PatientReferencesPageState();
}

class _PatientReferencesPageState
    extends State<PatientReferencesPage> {

  List references = [];
bool isLoading = true;

@override
void initState() {
  super.initState();
  loadReferences();
}

Future<void> loadReferences() async {
  try {

    final data =
        await ReferralService.getPatientReferences();

    setState(() {
      references = data;
      isLoading = false;
    });

  } catch(e) {

    print(e);

    setState(() {
      isLoading = false;
    });

  }
}

String formatStatus(String? status) {
  switch(status) {
    case "accepted":
      return "Accepté";

    case "rejected":
      return "Refusé";

    case "pending":
      return "En attente";

    default:
      return "En attente";
  }
}

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
  return const Center(
    child: CircularProgressIndicator(),
  );
}
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mes références",
        ),
      ),

      body: ListView.builder(
        itemCount: references.length,

        itemBuilder: (context,index){

          final ref = references[index];

         return Card(
  margin: const EdgeInsets.all(10),

  child: ListTile(
    leading: CircleAvatar(
      child: Text(
        (ref["doctor"] ?? "D")[0],
      ),
    ),

    title: Text(
      ref["doctor"] ?? "Médecin",
      style: const TextStyle(
        fontWeight: FontWeight.bold,
      ),
    ),

    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          ref["specialty"] ?? "",
        ),

        Text(
          ref["reason"] ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        Text(
          "Statut: ${formatStatus(ref["status"])}",
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