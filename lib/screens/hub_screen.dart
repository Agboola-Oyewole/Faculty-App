import 'package:faculty_app/components/hub_container.dart';
import 'package:faculty_app/screens/attendance_screen.dart';
import 'package:faculty_app/screens/excos_page.dart';
import 'package:faculty_app/screens/schedule_screen.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';
import '../components/exam_and_lecture_card.dart';
import '../utilities/utils.dart';

class HubScreen extends StatefulWidget {
  const HubScreen({super.key});

  @override
  State<HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<HubScreen> {
  Map<String, dynamic>? userData;
  List<Map<String, String>> items = [
    {
      "title": "Current Lecture Timetable",
      "image": "timetable-icon.png",
      "description": "Check your latest lecture times."
    },
    {
      "title": "Current Academic Calendar",
      "image": "calendar.png",
      "description": "View key academic dates."
    },
    {
      "title": "Current Exam Schedule",
      "image": "exam-time.png",
      "description": "See your upcoming exams."
    },
    {
      "title": "Attendance Taking (Beta)",
      "image": "team.png",
      "description": "Mark and track attendance."
    },
    {
      "title": "Lecture Schedule (Beta)",
      "image": "project.png",
      "description": "Get weekly lecture details."
    },
    {
      "title": "CGPA Calculator",
      "image": "calculator.png",
      "description": "Easily calculate your GPA."
    }
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserDetails();
  }

  Future<void> getUserDetails() async {
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (mounted && fetchedData != null) {
      setState(() {
        userData = fetchedData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNavBar()),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 20.0, left: 15.0, right: 15.0, bottom: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Hub',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Container(color: Colors.grey.withOpacity(0.5), height: 1.0),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.94,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                              items[index]['title'] ==
                                  "Current Lecture Timetable"
                                  ? ExamAndLectureCard(
                                title: 'Current Lecture Timetable',
                                firebaseCollection: 'lectures',
                              )
                                  : items[index]['title'] ==
                                  "Current Academic Calendar"
                                  ? ExamAndLectureCard(
                                title: 'Current Academic Calendar',
                                firebaseCollection: 'academic',
                              )
                                  : items[index]['title'] ==
                                  "Current Exam Schedule"
                                  ? ExamAndLectureCard(
                                title: 'Current Exam Schedule',
                                firebaseCollection: 'exams',
                              )
                                  : items[index]['title'] ==
                                  "CGPA Calculator"
                                  ? ExcosPage()
                                  : items[index]['title'] ==
                                  "Lecture Schedule (Beta)"
                                  ? WeeklyScheduleScreen()
                                  : userData?['role'] ==
                                  'student'
                                  ? AttendanceScreen()
                                  : AddClassScreen()));
                    },
                    child: HubContainer(
                      title: items[index]['title']!,
                      image: items[index]['image']!,
                      description: items[index]['description']!,
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
