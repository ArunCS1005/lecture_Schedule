import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';

class Lectureloader extends StatefulWidget {
  const Lectureloader({super.key});

  @override
  State<Lectureloader> createState() => _LectureloaderState();
}

class _LectureloaderState extends State<Lectureloader> {
  String? _selectedDay = DateFormat.EEEE().format(DateTime.now());

  Future<Map<String, dynamic>> fetchLectures() async {
    final String response = await rootBundle.loadString('assets/data.json');
    return json.decode(response);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchLectures(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available'));
          } else {
            final schedule = snapshot.data!['schedule'] as List<dynamic>;
            final daysOfWeek =
                schedule.map((e) => e['dayOfWeek'] as String).toList();
            if (_selectedDay == "Saturday" || _selectedDay == "Sunday") {
              return noLectures();
            }
            final filteredSchedule = _selectedDay != null
                ? schedule
                    .where((day) => day['dayOfWeek'] == _selectedDay)
                    .toList()
                : [];

            return Column(
              children: [
                DropdownButton<String>(
                  value: _selectedDay,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedDay = newValue;
                    });
                  },
                  items:
                      daysOfWeek.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  underline: Container(),
                  dropdownColor: Colors.white,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredSchedule.length,
                    itemBuilder: (context, index) {
                      final daySchedule = filteredSchedule[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Column(
                          children: (daySchedule['timeSlots'] as List)
                              .map<Widget>((timeSlot) {
                            return Column(
                              children: [
                                Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 30.0, vertical: 10.0),
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                    side: const BorderSide(
                                      color: Colors.grey,
                                      width: 1,
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Center(
                                      child: Text(
                                        timeSlot['lecture'],
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    subtitle: Center(
                                      child: Text(
                                        timeSlot['time'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
        shape: CircleBorder(),
      ),
    );
  }
}

Widget noLectures() {
  return const Center(
    child: Text(
      'No lectures on Saturday and Sunday',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}
