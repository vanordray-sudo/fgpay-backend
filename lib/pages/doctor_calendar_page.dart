import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/health_service.dart';

class DoctorCalendarPage extends StatefulWidget {
  const DoctorCalendarPage({super.key});

  @override
  State<DoctorCalendarPage> createState() => _DoctorCalendarPageState();
}

class _DoctorCalendarPageState extends State<DoctorCalendarPage> {
  bool isLoading = true;

  DateTime focusedDay = DateTime.now();
  DateTime? selectedDay;

  List<dynamic> availabilities = [];
  List<dynamic> unavailabilities = [];
  List<dynamic> selectedAvailabilities = [];

  @override
  void initState() {
    super.initState();
    selectedDay = DateTime.now();
    loadAvailabilities();
  }
Future<void> loadAvailabilities() async {
  final data = await HealthService.getDoctorAvailabilities();
  final unavailableData = await HealthService.getDoctorUnavailabilities();

  if (!mounted) return;

  setState(() {
    availabilities = data;
    unavailabilities = unavailableData;
    selectedAvailabilities = _getAvailabilitiesForDay(selectedDay!);
    isLoading = false;
  });
}

 bool _isUnavailable(DateTime day) {
  return unavailabilities.any((item) {
    final date = _cleanDate(item['unavailable_date']);
    return _sameDate(date, day);
  });
} 

  DateTime _cleanDate(dynamic value) {
    return DateTime.parse(value.toString()).toLocal();
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<dynamic> _getAvailabilitiesForDay(DateTime day) {
    return availabilities.where((item) {
      final date = _cleanDate(item['available_date']);
      return _sameDate(date, day);
    }).toList();
  }

  bool _hasAvailability(DateTime day) {
    return _getAvailabilitiesForDay(day).isNotEmpty;
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  String _formatTime(dynamic value) {
    final text = value.toString();
    if (text.length >= 5) {
      return text.substring(0, 5);
    }
    return text;
  }

Future<void> bookSelectedAppointment(
  Map<String, dynamic> item,
) async {
  final result = await HealthService.bookAppointment(
    doctorId: item['doctor_id'],
    doctorName: item['doctor_name'] ?? 'Médecin',
    clinicName: item['clinic_name'] ?? '',
    appointmentDate: item['available_date'],
    appointmentTime: item['start_time'],
  );

  if (!mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result['success'] == true
            ? 'Rendez-vous confirmé'
            : 'Erreur serveur',
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Almanak médecin'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2025, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: focusedDay,
                  selectedDayPredicate: (day) {
                    return selectedDay != null && _sameDate(day, selectedDay!);
                  },
                  onDaySelected: (selected, focused) {
                    setState(() {
                      selectedDay = selected;
                      focusedDay = focused;
                      selectedAvailabilities =
                          _getAvailabilitiesForDay(selected);
                    });
                  },
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                 calendarBuilders: CalendarBuilders(
  defaultBuilder: (context, day, focusedDay) {
    if (_isUnavailable(day)) {
      return Center(
        child: Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: Colors.red,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return null;
  },
  markerBuilder: (context, day, events) {
    if (_hasAvailability(day) && !_isUnavailable(day)) {
      return Positioned(
        bottom: 6,
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return null;
  },

                  ),
                ),

                const Divider(),

                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Disponibilités du ${_formatDate(selectedDay!)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: selectedAvailabilities.isEmpty
                      ? const Center(
                          child: Text('Aucune disponibilité ce jour'),
                        )
                      : ListView.builder(
                          itemCount: selectedAvailabilities.length,
                          itemBuilder: (context, index) {
                            final item = selectedAvailabilities[index]
                                as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: const Icon(
                                  Icons.access_time,
                                  color: Colors.green,
                                ),
                                title: Text(
                                  item['doctor_name'] ?? 'Médecin',
                                ),
                                subtitle: Text(
                                  '${item['clinic_name'] ?? ''}\n'
                                  '${_formatTime(item['start_time'])} - '
                                  '${_formatTime(item['end_time'])}',
                                ),

                                trailing: ElevatedButton(
  onPressed: () => bookSelectedAppointment(item),
  child: const Text('Prendre'),
),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}