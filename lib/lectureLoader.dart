import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class Lectureloader extends StatefulWidget {
  const Lectureloader({super.key});

  @override
  State<Lectureloader> createState() => _LectureloaderState();
}

class _LectureloaderState extends State<Lectureloader> {
  String? _selectedDay = DateFormat.EEEE().format(DateTime.now());
  bool _isEditMode = false;
  bool _isDeleteMode = false;

  //Features to be added

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

            final validSchedule =
                schedule.where((day) => day['dayOfWeek'] != null).toList();

            final daysOfWeek =
                validSchedule.map((e) => e['dayOfWeek'] as String).toList();

            if (_selectedDay == "Saturday" || _selectedDay == "Sunday") {
              return noLectures();
            }
            final filteredSchedule = _selectedDay != null
                ? validSchedule
                    .where((day) => day['dayOfWeek'] == _selectedDay)
                    .toList()
                : validSchedule;

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
                                    onTap: () {
                                      if (_isEditMode) {
                                        _editLecture(
                                            _selectedDay!,
                                            timeSlot['lecture'],
                                            timeSlot['time'],
                                            context);
                                      } else if (_isDeleteMode) {
                                        _deleteLecture(
                                            _selectedDay!,
                                            timeSlot['lecture'],
                                            timeSlot['time'],
                                            context);
                                      }
                                    },
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
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        animatedIconTheme: const IconThemeData(size: 22.0),
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Add Lecture',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => _showAddLectureDialog(context),
            shape: const CircleBorder(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.edit),
            label: 'Edit Lecture',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => _isEditMode = !_isEditMode,
            shape: const CircleBorder(),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: 'Delete Lecture',
            labelStyle: const TextStyle(fontSize: 18.0),
            onTap: () => _isDeleteMode = !_isDeleteMode,
            shape: const CircleBorder(),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> fetchLectures() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/data.json');

    if (await file.exists()) {
      final String response = await file.readAsString();
      print(json.decode(response));
      return json.decode(response);
    } else {
      // Initialize the file with the provided structure
      final initialData = {
        "schedule": [
          {"dayOfWeek": "Monday", "timeSlots": []},
          {"dayOfWeek": "Tuesday", "timeSlots": []},
          {"dayOfWeek": "Wednesday", "timeSlots": []},
          {"dayOfWeek": "Thursday", "timeSlots": []},
          {"dayOfWeek": "Friday", "timeSlots": []}
        ]
      };
      await file.writeAsString(json.encode(initialData));
      print('File created');
      print(initialData);
      return initialData;
    }
  }

  void _showAddLectureDialog(BuildContext context) {
    final _lectureController = TextEditingController();
    TimeOfDay? _selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Lecture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _lectureController,
                decoration: const InputDecoration(labelText: 'Lecture Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Time',
                  hintText: _selectedTime?.format(context)
                ),
                onTap: () async {
                  _selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  setState(() {}); // Update the UI to show the selected time
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_lectureController.text.isNotEmpty &&
                    _selectedTime != null) {
                  _addLecture(_lectureController.text, _selectedTime!);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addLecture(String lectureName, TimeOfDay time) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/data.json');

    if (await file.exists()) {
      final String response = await file.readAsString();
      final data = json.decode(response);

      final formattedTime = time.format(context);

      // Find the selected day in the schedule
      final selectedDay = data['schedule'].firstWhere(
        (day) => day['dayOfWeek'] == _selectedDay,
        orElse: () => null,
      );

      if (selectedDay != null) {
        selectedDay['timeSlots'].add({
          'lecture': lectureName,
          'time': formattedTime,
        });
      } else {
        data['schedule'].add({
          'dayOfWeek': _selectedDay,
          'timeSlots': [
            {
              'lecture': lectureName,
              'time': formattedTime,
            },
          ],
        });
      }

      await file.writeAsString(json.encode(data));
      setState(() {});
    }
  }

  void _editLecture(String dayOfWeek, String currentLecture,
      String currentTimeslot, BuildContext context) {
    final _lectureController = TextEditingController(text: currentLecture);
    final _timeController = TextEditingController(text: currentTimeslot);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Lecture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _lectureController,
                decoration: InputDecoration(labelText: 'Lecture'),
              ),
              TextField(
                controller: _timeController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Time',
                  hintText: currentTimeslot,
                ),
                onTap: () async {
                  TimeOfDay initialTime = TimeOfDay(
                    hour: int.parse(currentTimeslot.split(":")[0]),
                    minute: int.parse(currentTimeslot.split(":")[1]),
                  );
                  TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: initialTime,
                  );
                  if (picked != null) {
                    _timeController.text = picked.format(context);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/data.json');
                String jsonString = await file.readAsString();
                Map<String, dynamic> jsonData = json.decode(jsonString);

                // Find the dayOfWeek and update the lecture and timeslot
                for (var day in jsonData['schedule']) {
                  if (day['dayOfWeek'] == dayOfWeek) {
                    for (var slot in day['timeSlots']) {
                      if (slot['lecture'] == currentLecture &&
                          slot['time'] == currentTimeslot) {
                        slot['lecture'] = _lectureController.text;
                        slot['time'] = _timeController.text;
                        break;
                      }
                    }
                    break;
                  }
                }

                // Save the updated data back to the JSON file
                await file.writeAsString(json.encode(jsonData));
                setState(() {});
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _deleteLecture(
      String dayOfWeek, String lecture, String timeslot, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Lecture'),
          content: Text('Are you sure you want to delete this lecture?'),
          actions: [
            TextButton(
              onPressed: () async {
                final directory = await getApplicationDocumentsDirectory();
                final file = File('${directory.path}/data.json');
                String jsonString = await file.readAsString();
                Map<String, dynamic> jsonData = json.decode(jsonString);

                // Find the dayOfWeek and delete the lecture and timeslot
                for (var day in jsonData['schedule']) {
                  if (day['dayOfWeek'] == dayOfWeek) {
                    day['timeSlots'].removeWhere((slot) =>
                        slot['lecture'] == lecture && slot['time'] == timeslot);
                    break;
                  }
                }

                // Save the updated data back to the JSON file
                await file.writeAsString(json.encode(jsonData));
                setState(() {});
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
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
}
