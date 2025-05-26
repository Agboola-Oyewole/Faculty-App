import 'package:faculty_app/lecturer/lecturer_course_details.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';
import '../components/folder_card.dart';
import '../utilities/utils.dart';

class LecturerCoursesScreen extends StatefulWidget {
  const LecturerCoursesScreen({super.key});

  @override
  State<LecturerCoursesScreen> createState() => _LecturerCoursesScreenState();
}

class _LecturerCoursesScreenState extends State<LecturerCoursesScreen> {
  List<String> _courses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    initCourseData();
  }

  Map<String, dynamic>? courseData;

  Future<void> initCourseData() async {
    setState(() {
      _isLoading = true;
    });
    Map<String, Map<String, dynamic>>? data = await loadCourseDataFromPrefs();

    if (mounted) {
      if (data != null) {
        setState(() {
          courseData = data;
          print(courseData);
        });
        print(courseData);
      } else {
        print("No cached data");
      }
      setState(() {
        _isLoading = false;
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
              'Courses',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Container(color: Colors.grey.withOpacity(0.5), height: 1.0),
            SizedBox(
              height: 10,
            ),
            SizedBox(
              height: 20,
            ),
            _isLoading
                ? Expanded(
                    child: Center(
                        child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.black,
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Loading your courses")
                    ],
                  )))
                : courseData!.isEmpty
                    ? Expanded(child: Center(child: Text("No resources found")))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: courseData!.length,
                          itemBuilder: (context, index) {
                            String courseCode =
                                courseData!.keys.elementAt(index);
                            int unit = courseData![courseCode]!['unit'];
                            List<dynamic> department =
                                courseData![courseCode]!['department'];
                            String level = courseData![courseCode]!['level'];
                            String semester =
                                courseData![courseCode]!['semester'];
                            String name = courseData![courseCode]!['full_name'];

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LecturerCourseDetails(
                                      courseId: courseCode,
                                      name: name,
                                      unit: unit,
                                    ),
                                  ),
                                );
                              },
                              child: FolderCard(
                                courseCode: courseCode,
                                unit: unit,
                                department: department,
                                level: level,
                                semester: semester,
                                name: name,
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
}
