import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'auth_service.dart';
import '../config/api_config.dart';


class MedicalRecordService {
  static const String baseUrl =
      'http://localhost:3000/api/medical-records';

  


static Future<List<dynamic>> getPatientRecords(
    int patientId) async {

  final token =
      await AuthService.getToken();

  final response = await http.get(
   Uri.parse('${ApiConfig.baseUrl}/medical-records/patient'),

    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  print(
      'MEDICAL HISTORY: ${response.body}');

  if (response.statusCode == 200) {
    return jsonDecode(
      response.body,
    );
  }

  return [];
}

 static Future<bool> createRecord({
  required int patientId,
  required String title,
  required String type,
  required String description,
  required String doctorName,
  required String clinicName,
  PlatformFile? file,
}) async {

  try {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/create'),
    );

    request.headers['Authorization'] =
        'Bearer $token';

    request.fields['patient_id'] =
        patientId.toString();

    request.fields['title'] = title;

    request.fields['type'] = type;

    request.fields['description'] =
        description;

    request.fields['doctor_name'] = doctorName;
    request.fields['clinic_name'] = clinicName;

  if (file != null && file.bytes != null) {
  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      file.bytes!,
      filename: file.name,
    ),
  );
}
final response =
    await request.send();

final responseBody =
    await response.stream.bytesToString();

print('ADD RECORD STATUS: ${response.statusCode}');
print('ADD RECORD BODY: $responseBody');

if (response.statusCode == 200 ||
    response.statusCode == 201) {
  return true;
}

return false;

  } catch (e) {

    print(e);

    return false;
  }
}


static Future<List<dynamic>>getPatientMedicalRecords(
int patientId) async {

 final token =
 await AuthService.getToken();

 final response =
 await http.get(

Uri.parse('${ApiConfig.baseUrl}/api/medical-records/patient/$patientId'),

headers:{

'Content-Type':
'application/json',

'Authorization':
'Bearer $token'

}

);

print('PATIENT MEDICAL RECORD STATUS: ${response.statusCode}');
  print('PATIENT MEDICAL RECORD BODY: ${response.body}');

if(response.statusCode==200){

return jsonDecode(
response.body
);

}

return [];
}

}

