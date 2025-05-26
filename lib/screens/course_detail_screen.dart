import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/screens/course_file_assignments.dart';
import 'package:faculty_app/screens/course_material_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String name;
  final List<dynamic> department;
  final String link1;
  final int unit;
  final String link2;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.name,
    required this.department,
    required this.unit,
    required this.link1,
    required this.link2,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  List<String> lecturerNames = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getLecturersForCourse(widget.courseId);
  }

  bool isLoading = false;
  List<Map<String, String>> items = [
    {"title": "Course Material", "description": "View course materials."},
    {"title": "Past Question", "description": "View course past questions."},
    {
      "title": "Announcements",
      "description": "View announcements uploaded by lecturers."
    },
    {"title": "Assignments", "description": "View course assignments."},
  ];

  List<Icon> icons = [
    Icon(Icons.menu_book_outlined, color: Colors.black, size: 15),
    Icon(Icons.question_answer_outlined, color: Colors.black, size: 15),
    Icon(Icons.campaign, color: Colors.black, size: 15),
    Icon(Icons.assignment, color: Colors.black, size: 15)
  ];

  Future<void> getLecturersForCourse(String courseId) async {
    setState(() {
      isLoading = true;
    });
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'lecturer')
          .get();

      List<String> matchedLecturers = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final courses = List<String>.from(data['courses'] ?? []);

        if (courses.contains(courseId)) {
          matchedLecturers.add(data['username']);
        }
      }
      setState(() {
        lecturerNames = matchedLecturers;
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error getting lecturers for course: $e");
      setState(() {
        isLoading = false;
      });
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Exit the app
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => BottomNavBar(
                        initialIndex: 1,
                      )));
        }
      },
      child: Scaffold(
        backgroundColor: isLoading ? Colors.white : Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme:
              IconThemeData(color: isLoading ? Colors.black : Colors.white),
          // 👈 back button color
          title: Text(
            'Course Details',
            style: TextStyle(
                color: isLoading ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18),
          ),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.black, // Customize color
                  strokeWidth: 4,
                ),
              )
            : Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        widget.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 15),
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                color: Colors.white,
                                size: 13,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                '${widget.courseId}    ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                          Text('|    ',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text('${widget.unit} Units',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 12,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 13,
                            ),
                            SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Lecturer: ${lecturerNames.isEmpty ? 'No assigned lecturer currently.' : lecturerNames.join(", ")}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15))),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 40.0, left: 20.0, right: 20.0, bottom: 0.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: GridView.builder(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: kIsWeb
                                      ? MediaQuery.of(context).size.width /
                                          (MediaQuery.of(context).size.height /
                                              1.9)
                                      : MediaQuery.of(context).size.width /
                                          (MediaQuery.of(context).size.height /
                                              2.3),
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => items[index]
                                                      ['title'] ==
                                                  'Announcements'
                                              ? CourseAssignmentFileScreen(
                                                  courseId: widget.courseId,
                                                  courseUnit: widget.unit,
                                                  type: items[index]['title'] ==
                                                          'Announcements'
                                                      ? 'Announcements'
                                                      : 'Assignments')
                                              : items[index]['title'] ==
                                                      'Assignments'
                                                  ? CourseAssignmentFileScreen(
                                                      courseId: widget.courseId,
                                                      courseUnit: widget.unit,
                                                      type: items[index]
                                                                  ['title'] ==
                                                              'Assignments'
                                                          ? 'Assignments'
                                                          : 'Announcements')
                                                  : CourseMaterialScreen(
                                                      courseId: widget.courseId,
                                                      courseUnit: widget.unit,
                                                      courseDept:
                                                          widget.department,
                                                      link: widget.link1,
                                                      link2: widget.link2,
                                                      type: items[index]
                                                                  ['title'] ==
                                                              'Course Material'
                                                          ? 'Lecture Notes'
                                                          : 'Past Questions'),
                                        ),
                                      );
                                    },
                                    child: courseDetailCard(
                                        icons[index],
                                        items[index]['title'],
                                        items[index]['description']),
                                  );
                                },
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }

  Widget courseDetailCard(icon, text, description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(5)),
              border: Border.all(color: Colors.black, width: .5)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(5.0)),
                      border: Border.all(color: Colors.black, width: 1)),
                  padding: const EdgeInsets.all(8.0),
                  child: icon),
              SizedBox(height: 10),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
