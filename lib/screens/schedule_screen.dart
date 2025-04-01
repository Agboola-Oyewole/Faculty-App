import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<String> orderedDays = [
    "Monday",
    "Tuesday",
    "Wednesday",
    "Thursday",
    "Friday",
    "Saturday",
    "Sunday"
  ];

  Map<String, List<Map<String, dynamic>>> schedules = {
    "Monday": [],
    "Tuesday": [],
    "Wednesday": [],
    "Thursday": [],
    "Friday": [],
    "Saturday": [],
    "Sunday": [],
  };

  String? _selectedCourseCode;

  List<String> courseCodes = [];

  @override
  void initState() {
    super.initState();
    fetchUserCourseCodes();
    _fetchUserSchedules();
  }

  Future<void> fetchUserCourseCodes() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!doc.exists) return;

      String userLevel = doc.data()?['level'] ?? '';
      String userDepartment = doc.data()?['department'] ?? '';
      String userSemester = doc.data()?['semester'] ?? '';

      QuerySnapshot filesSnapshot =
          await FirebaseFirestore.instance.collectionGroup("files").get();

      Set<String> tempCourseCodes = {};

      for (var fileDoc in filesSnapshot.docs) {
        Map<String, dynamic> data = fileDoc.data() as Map<String, dynamic>;

        if (!data.containsKey('course_code')) continue;

        String courseCode = data['course_code'] ?? 'Unknown';
        String resourceLevel = data['level'] ?? '';
        String resourceDepartment = data['department'] ?? '';
        String resourceSemester = data['semester'] ?? '';

        bool levelMatch = (resourceLevel == userLevel);
        bool departmentMatch = (resourceDepartment == userDepartment ||
            resourceDepartment == "All");
        bool semesterMatch = (resourceSemester == userSemester);

        if (levelMatch && departmentMatch && semesterMatch) {
          tempCourseCodes.add(courseCode);
        }
      }

      setState(() {
        courseCodes = tempCourseCodes.toList();
      });
    } catch (e) {
      print('❌ Error fetching course codes: $e');
    }
  }

  Future<void> deleteSchedule(
      String userId, String day, Map<String, dynamic> scheduleItem) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    DocumentReference userDoc = firestore.collection('schedules').doc(userId);

    try {
      await userDoc.update({
        "schedule.$day": FieldValue.arrayRemove([scheduleItem])
      });

      print("Schedule deleted successfully for $day!");
      _fetchUserSchedules();
    } catch (e) {
      print("Error deleting schedule: $e");
    }
  }

  void confirmDelete(documentId, String day, Map<String, dynamic> schedule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Lecture Time?",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text("Are you sure you want to delete this lecture?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              deleteSchedule(userId!, day, schedule);
              Navigator.pop(context);
            },
            child: Text("Delete",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showDeleteBottomSheet(BuildContext context, documentId, String day,
      Map<String, dynamic> schedule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push content up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: Wrap(children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff347928),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(documentId, day, schedule);
                },
                child: Text("Delete Lecture",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> _fetchUserSchedules() async {
    setState(() {
      isLoading = true;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef =
        FirebaseFirestore.instance.collection('schedules').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;
      Map<String, dynamic> fetchedSchedule = data["schedule"] ?? {};

      setState(() {
        schedules = fetchedSchedule.map((day, events) {
          return MapEntry(
            day,
            (events as List).cast<Map<String, dynamic>>().map((event) {
              return {
                "name": event["name"] ?? "",
                "startTime": event["startTime"] is Timestamp
                    ? (event["startTime"] as Timestamp).toDate()
                    : null,
                "endTime": event["endTime"] is Timestamp
                    ? (event["endTime"] as Timestamp).toDate()
                    : null,
              };
            }).toList(),
          );
        });
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  String convertToTimestamp(BuildContext context, String timeString) {
    // Get current date
    DateTime now = DateTime.now();

    try {
      DateFormat inputFormat;

      // Check if timeString contains AM or PM (12-hour format)
      if (timeString.contains("AM") || timeString.contains("PM")) {
        inputFormat = DateFormat("h:mm a"); // 12-hour format
      } else {
        inputFormat = DateFormat("HH:mm"); // 24-hour format
      }

      // Parse input time
      DateTime parsedTime = inputFormat.parse(timeString);

      // Combine current date with parsed time
      DateTime finalDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        parsedTime.hour,
        parsedTime.minute,
      );

      // Convert to UTC and return ISO 8601 format
      return finalDateTime.toUtc().toIso8601String();
    } catch (e) {
      print("❌ Error parsing time: $e");
      return now
          .toUtc()
          .toIso8601String(); // Default to current time if parsing fails
    }
  }

  Future<void> addScheduleEvent(BuildContext context, String day,
      TimeOfDay startTime, TimeOfDay? endTime) async {
    setState(() {
      isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userId = user.uid;
      final docRef =
          FirebaseFirestore.instance.collection('schedules').doc(userId);

      // Get the current schedule from Firestore
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic> data = docSnapshot.data() as Map<String, dynamic>;

        // Extract current schedule
        Map<String, dynamic> schedule = data["schedule"] ?? {};

        // Ensure the selected day exists as a list
        List<dynamic> eventsForDay = List.from(schedule[day] ?? []);

        // Add the new event
        eventsForDay.add({
          "name": _selectedCourseCode,
          "startTime": Timestamp.fromDate(DateTime.parse(
              convertToTimestamp(context, startTime.format(context)))),
          "endTime": Timestamp.fromDate(DateTime.parse(
              convertToTimestamp(context, endTime!.format(context))))
        });

        // Update Firestore
        await docRef.update({
          "schedule.$day": eventsForDay, // Only updates the selected day
        });
        print("I'm here now, this worked then.");
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String formatDateTime(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat.jm().format(timestamp.toDate());
    } else if (timestamp is DateTime) {
      return DateFormat.jm().format(timestamp);
    } else {
      return "Invalid Time";
    }
  }

  Widget _buildDropdown(String hint, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$hint is required"; // Show validation message
        }
        return null;
      },
    );
  }

  // Function to show bottom modal sheet
  void _showAddScheduleModal(BuildContext context, String day) {
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel",
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                      ),
                      Text(
                        "New Lecture Time",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            // Validate the form
                            if (_selectedCourseCode!.isNotEmpty &&
                                startTime != null) {
                              setState(() {
                                schedules[day]!.add({
                                  "name": _selectedCourseCode,
                                  "startTime": startTime!.format(context),
                                  "endTime": endTime?.format(context) ?? ''
                                });
                              });

                              print('ABOUT TO ADD SCHEDULE');
                              await addScheduleEvent(
                                  context, day, startTime!, endTime);
                              print(schedules);
                              _fetchUserSchedules(); // Refresh UI after adding
                              Navigator.pop(context);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text("Course Code not selected!")),
                              );
                            }
                          }
                        },
                        child: Text("Save",
                            style: TextStyle(
                                color: Color(0xff347928), fontSize: 16)),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _formKey, // Assign form key
                    child: _buildDropdown(
                        "Course Code", courseCodes, _selectedCourseCode,
                        (newValue) {
                      setState(() => _selectedCourseCode = newValue);
                    }),
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _timePickerButton(
                          context,
                          label: "Start Time",
                          time: startTime,
                          onTimeSelected: (picked) {
                            setModalState(() => startTime = picked);
                          },
                        ),
                        Icon(Icons.arrow_forward),
                        _timePickerButton(
                          context,
                          label: "End Time",
                          time: endTime,
                          onTimeSelected: (picked) {
                            setModalState(() => endTime = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  ListTile(
                    leading: Icon(Icons.calendar_today),
                    title: Text(day),
                    trailing: Icon(Icons.check_circle_rounded),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Widget for picking time
  Widget _timePickerButton(BuildContext context,
      {required String label,
      required TimeOfDay? time,
      required Function(TimeOfDay) onTimeSelected}) {
    return TextButton(
      onPressed: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (pickedTime != null) {
          onTimeSelected(pickedTime);
        }
      },
      child: Row(
        children: [
          Icon(Icons.access_time, color: Colors.blue),
          SizedBox(width: 5),
          Text(
            time != null ? time.format(context) : label,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffF1EFEC),
      appBar: AppBar(
        backgroundColor: Color(0xffF1EFEC),
        title: Text("Weekly Schedule"),
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Colors.black,
                value: 0.3, // Progress value (0.0 - 1.0)
                strokeWidth: 3, // Thickness of the indicator
              ),
            )
          : Padding(
              padding: const EdgeInsets.only(top: 5.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // Aligns text to the left
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 15.0),
                    child: Row(
                      children: [
                        Icon(Icons.info),
                        SizedBox(width: 10),
                        Expanded(
                          // Ensures text wraps instead of overflowing
                          child: Text(
                            "Add your course codes based on your lecture timetable to receive alerts before your classes start.",
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                            // Reduce font size if needed
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: orderedDays.map((day) {
                        return ExpansionTile(
                          title: Text(
                            day,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          children: [
                            if (schedules[day] == null ||
                                schedules[day]!.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text("No schedules for today"),
                              )
                            else
                              ...schedules[day]!.map((schedule) {
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  child: ListTile(
                                    title: Text(schedule["name"]!,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                            "Time: ${formatDateTime(schedule["startTime"])} "),
                                        Text(
                                            "- ${formatDateTime(schedule["endTime"])}"),
                                      ],
                                    ),
                                    trailing: GestureDetector(
                                      onTap: () {
                                        showDeleteBottomSheet(
                                            context, userId, day, schedule);
                                      },
                                      child: Icon(Icons.more_vert),
                                    ),
                                  ),
                                );
                              }),
                            // Add Schedule Button
                            TextButton.icon(
                              onPressed: () =>
                                  _showAddScheduleModal(context, day),
                              icon: Icon(Icons.add, color: Color(0xff347928)),
                              label: Text("Add Schedule",
                                  style: TextStyle(color: Color(0xff347928))),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
