import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MedicalResultsPage extends StatefulWidget {
  final bool isAdmin;

  const MedicalResultsPage({
    super.key,
    this.isAdmin = false,
  });

  @override
  State<MedicalResultsPage> createState() => _MedicalResultsPageState();
}

class _MedicalResultsPageState
    extends State<MedicalResultsPage> {

List<Map<String, dynamic>> results = [];
bool isLoading = true;

@override
void initState() {
  super.initState();
  loadResults();
}

Future<void> loadResults() async {
  try {
   final token = await AuthService.getToken();

if (token == null || token.isEmpty) {
  setState(() {
    isLoading = false;
  });
  return;
} 

  final url = widget.isAdmin
    ? 'http://localhost:3000/api/health/medical-results'
    : 'http://localhost:3000/api/health/my-medical-results';

final response = await http.get(
  Uri.parse(url),
  headers: {
    'Authorization': 'Bearer $token',
  },
);
     
   final data = jsonDecode(response.body);
   print('MEDICAL RESULTS = $data');

setState(() {
  results = List<Map<String, dynamic>>.from(
    data is List ? data : data['results'] ?? [],
  );
  isLoading = false;
}); 


  } catch (e) {
    print(e);
    setState(() {
      isLoading = false;
    });
  }
}
  @override
  Widget build(BuildContext context) {
     

Future<void> _uploadMedicalResult() async {
  try {

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'png'],
    );

    if (result == null) return;

    final file = result.files.first;

   final request = http.MultipartRequest(
  'POST',
  Uri.parse('http://localhost:3000/api/health/medical-results/upload'),
);


    const token = 

     'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MywiaWF0IjoxNzc4Mjc5NTc3LCJleHAiOjE3Nzg4ODQzNzd9.jJD9eAUu2ZyvDppl3_NtXcUF1Pumk3f6uPPJ9X1hMBc';
  request.headers['Authorization'] = 'Bearer $token';
    
   
request.fields['title'] = file.name;
request.fields['resultType'] = 'Laboratoire';
request.fields['patientPhone'] = '50922222222';

request.files.add(
  http.MultipartFile.fromBytes(
    'file',
    file.bytes!,
    filename: file.name,
  ),
);

final response = await request.send();

final responseBody = await response.stream.bytesToString();

print('UPLOAD STATUS: ${response.statusCode}');
print('UPLOAD BODY: $responseBody');

    if (response.statusCode == 200) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Document uploadé',
          ),
        ),
      );
    } else {
      print(responseBody);
    }

  } catch (e) {
    print(e);
  }
}



    return Scaffold(
     appBar: AppBar(
  title: const Text('Mes résultats médicaux'),

  backgroundColor: Colors.green,
  foregroundColor: Colors.white,

  actions: [
    IconButton(
      icon: const Icon(Icons.upload_file),

      onPressed: _uploadMedicalResult,
    ),
  ],
),
     body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : results.isEmpty
        ? const Center(child: Text('Aucun résultat médical'))
        : ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final item = results[index];

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  leading: const Icon(Icons.folder_copy, color: Colors.green),
                  title: Text(item['title'] ?? ''),
                  subtitle: Text(
                    '${item['result_type'] ?? ''} • ${item['created_at'] ?? ''}',
                  ),
                  trailing: IconButton(
  icon: const Icon(Icons.visibility),
  onPressed: () async {
    final url =
        'http://localhost:3000${item['file_url']}';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    }
  },
),
                 onTap: () async {
  final fileUrl = item['file_url'];

  final url = fileUrl.toString().startsWith('http')
      ? fileUrl
      : 'http://127.0.0.1:3000$fileUrl';

  await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
}, 
                ),
              );
            },
          ),
    );
  }
    }
    