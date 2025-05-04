import 'package:faculty_app/components/folder_card.dart';
import 'package:faculty_app/screens/course_detail_screen.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';
import '../utilities/utils.dart';

class CourseScreen extends StatefulWidget {
  const CourseScreen({super.key});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  Map<String, dynamic>? userData;
  Map<String, Map<String, dynamic>>? courseData;
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCourseData();
    getUserDetails();
  }

  Future<void> initCourseData() async {
    setState(() {
      isLoading = true;
    });
    Map<String, Map<String, dynamic>>? data = await loadCourseDataFromPrefs();

    if (mounted) {
      if (data != null) {
        setState(() {
          courseData = data;
        });
        print(courseData);
      } else {
        print("No cached data");
      }
    }
  }

  Future<void> getUserDetails() async {
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (mounted && fetchedData != null) {
      setState(() {
        userData = fetchedData;
      });
    }
    if (mounted) {
      setState(() {
        isLoading = false;
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
            isLoading
                ? Container()
                : Material(
                    borderRadius: BorderRadius.circular(5),
                    elevation: 2,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(color: Colors.black, width: .5)),
                      child: Row(children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffDBDBDB).withOpacity(0.5),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(5.0)),
                                ),
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  Icons.info_outlined,
                                  size: 17,
                                ),
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: Text(
                                  "${userData!['level'] ?? 'Loading data....'}  ${userData!['semester'] ?? ''}",
                                  // Lecture title
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
            SizedBox(
              height: 20,
            ),
            isLoading
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

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CourseDetailScreen(
                                      courseId: courseCode,
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
