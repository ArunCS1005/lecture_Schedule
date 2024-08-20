import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lottie/lottie.dart';

class Lectureloader extends StatefulWidget {
  const Lectureloader({super.key});

  @override
  State<Lectureloader> createState() => _LectureloaderState();
}

class _LectureloaderState extends State<Lectureloader> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String? _selectedDay = DateFormat.EEEE().format(DateTime.now());

  //Features to be added

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body:  FutureBuilder<Map<String, dynamic>>(
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
          
                final filteredSchedule = _selectedDay != null
                    ? validSchedule
                        .where((day) => day['dayOfWeek'] == _selectedDay)
                        .toList()
                    : validSchedule;
          
          
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          height: 70,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                                "No. of lectures: ${filteredSchedule[0]['timeSlots'].length}",
                                style: const TextStyle(
                                  fontSize: 18,
                                )),
                          ),
                        ),
                        Container(
                          height: 70,
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: Colors.grey,
                              width: 2,
                            ),
                          ),
                          child: DropdownButton<String>(
                            padding: const EdgeInsets.all(8.0),
                            elevation: 10,
                            underline: Container(),
                            value: _selectedDay,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedDay = newValue!;
                              });
                            },
                            items: <String>[
                              'Monday',
                              'Tuesday',
                              'Wednesday',
                              'Thursday',
                              'Friday',
                              'Saturday',
                              'Sunday'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                    if ((_selectedDay == 'Saturday' || _selectedDay == 'Sunday') && filteredSchedule[0]['timeSlots'].isEmpty)
                      weekend()
                    else if (filteredSchedule[0]['timeSlots'].isEmpty)
                      noLectures()
                    else
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
                                        elevation: 10,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(15.0),
                                          side: const BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          title: Row(
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.fromLTRB(
                                                    15, 0, 10, 0),
                                                child: Text(
                                                  '${timeSlot['time']}', // Hours and Minutes
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height:
                                                    50, 
                                                child: VerticalDivider(
                                                  color: Colors.grey,
                                                  thickness: 2,
                                                ),
                                              ),
                                              // Lecture Name
                                              Expanded(
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                          horizontal: 20.0),
                                                  child: Text(
                                                    timeSlot['lecture'],
                                                    style: const TextStyle(
                                                      fontSize: 24,
                                                      fontWeight: FontWeight.w400,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: PopupMenuButton<String>(
                                            onSelected: (String result) {
                                              if (result == 'Edit') {
                                                _editLecture(
                                                    daySchedule['dayOfWeek'],
                                                    timeSlot['lecture'],
                                                    timeSlot['time'],
                                                    context);
                                              } else if (result == 'Delete') {
                                                _deleteLecture(
                                                    daySchedule['dayOfWeek'],
                                                    timeSlot['lecture'],
                                                    timeSlot['time'],
                                                    context);
                                              }
                                            },
                                            itemBuilder: (BuildContext context) =>
                                                <PopupMenuEntry<String>>[
                                              const PopupMenuItem<String>(
                                                value: 'Edit',
                                                child: Text('Edit'),
                                              ),
                                              const PopupMenuItem<String>(
                                                value: 'Delete',
                                                child: Text('Delete'),
                                              ),
                                            ],
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
        
      
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLectureDialog(context),
        label: const Text("Add Lecture",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        elevation: 15,
        icon: const Icon(Icons.add),
        extendedIconLabelSpacing: 10,
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
          {"dayOfWeek": "Friday", "timeSlots": []},
          {"dayOfWeek": "Saturday", "timeSlots": []},
          {"dayOfWeek": "Sunday", "timeSlots": []}
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
    final _timeController =
        TextEditingController(); // Define _timeController variable
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
                textCapitalization: TextCapitalization.words,
                controller: _lectureController,
                decoration: const InputDecoration(labelText: 'Lecture Name'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller:
                    _timeController, // Assign _timeController to the TextField
                onTap: () async {
                  _selectedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (_selectedTime != null) {
                    setState(() {
                      _timeController.text = _selectedTime!.format(context);
                    });
                  }
                },
                decoration: InputDecoration(
                    labelText: 'Time',
                    hintText: _selectedTime.toString() == 'null'
                        ? 'Select Time'
                        : _selectedTime.toString()),
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
          title: const Text('Edit Lecture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _lectureController,
                decoration: const InputDecoration(labelText: 'Lecture'),
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
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
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
          title: const Text('Delete Lecture'),
          content: const Text('Are you sure you want to delete this lecture?'),
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
              child: const Text('Delete'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget noLectures() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/book.json'),
        const SizedBox(height: 20),
        const Text(
          'Add lectures to get started',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}

  Widget weekend() {
    return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Lottie.asset('assets/bells.json'),
        const SizedBox(height: 20),
        const Text(
          'Enjoy your weekend!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
  }

  SnackBar showSnackbar(String s) {
    return SnackBar(
      content: Text(s),
      duration: const Duration(seconds: 2),
    );
  }
}
