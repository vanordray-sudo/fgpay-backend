import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DoctorAvailabilityPage extends StatefulWidget {
  const DoctorAvailabilityPage({super.key});

  @override
  State<DoctorAvailabilityPage> createState() =>
      _DoctorAvailabilityPageState();
      
}

class _DoctorAvailabilityPageState
    extends State<DoctorAvailabilityPage> {

  final String baseUrl ='http://localhost:3000/api/doctor-availabilities';

  List availabilities = [];

  DateTime? selectedDate;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  @override
void initState() {
  super.initState();

  _loadAvailabilities();
}

Future<void> _loadAvailabilities() async {

  try {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$baseUrl/mine'),

      headers: {
        'Authorization': 'Bearer $token',
      },
    );

   if (response.statusCode == 200) {

  await _loadAvailabilities();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Disponibilité enregistrée',
      ),
    ),
  );

  Navigator.pop(context);
}

  } catch (e) {

    print(e);
  }
}

  Future<void> pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

Future<void> saveAvailability() async {
  if (selectedDate == null || startTime == null || endTime == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Choisissez une date, heure début et heure fin'),
      ),
    );
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/add'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'available_date': selectedDate!.toIso8601String().split('T')[0],
        'start_time':
            '${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}:00',
        'end_time':
            '${endTime!.hour.toString().padLeft(2, '0')}:${endTime!.minute.toString().padLeft(2, '0')}:00',
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disponibilité enregistrée')),
      );
      await _loadAvailabilities();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur serveur: ${response.body}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: $e')),
    );
  }
}
  Future<void> pickStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        startTime = time;
      });
    }
  }

  Future<void> pickEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null) {
      setState(() {
        endTime = time;
      });
    }
  }

  String formatDate(DateTime? date) {
  if (date == null) return 'Choisir une date';

  return '${date.day}/${date.month}/${date.year}';
}

String formatTime(TimeOfDay? time) {
  if (time == null) return '--:--';

  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilités médecin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _choiceCard(
              icon: Icons.calendar_month,
              title: 'Date',
              value: formatDate(selectedDate),
              onTap: pickDate,
            ),

            _choiceCard(
              icon: Icons.access_time,
              title: 'Heure début',
              value: formatTime(startTime),
              onTap: pickStartTime,
            ),

            _choiceCard(
              icon: Icons.access_time_filled,
              title: 'Heure fin',
              value: formatTime(endTime),
              onTap: pickEndTime,
            ),

             const SizedBox(height: 24),

           SizedBox(
  width: double.infinity,
  height: 52,
  child: ElevatedButton.icon(
    onPressed: saveAvailability,
    icon: const Icon(Icons.save),
    label: const Text('Enregistrer disponibilité'),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  ),
           ),
      
     

              const Text(
  'Mes disponibilités',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 12),

Expanded(
  child: availabilities.isEmpty
      ? const Center(
          child: Text('Aucune disponibilité enregistrée'),
        )
      : ListView.builder(
          itemCount: availabilities.length,
          itemBuilder: (context, index) {
            final availability = availabilities[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  '${availability['available_date']}',
                ),
                subtitle: Text(
                  '${availability['start_time']} → ${availability['end_time']}',
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onPressed: () async {
                    final prefs =
                        await SharedPreferences.getInstance();

                    final token = prefs.getString('token');

                    await http.delete(
                      Uri.parse('$baseUrl/${availability['id']}'),
                      headers: {
                        'Authorization': 'Bearer $token',
                      },
                    );

                    _loadAvailabilities();
                  },
                ),
              ),
            );
          },
        ),
),
            
          ],
        ),
      ),
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:  Colors.green,
          child: Icon(icon, color: Colors.green),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}