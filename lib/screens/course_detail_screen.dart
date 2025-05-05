import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/screens/course_material_screen.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic> courseDetails = {};
  bool isLoading = false;

  Future<Map<String, dynamic>?> getCourseDetails(String courseId) async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
    final doc = await FirebaseFirestore.instance
        .collection("resources")
        .doc(courseId)
        .get();

    if (doc.exists) {
      final data = doc.data(); // This already returns a Map<String, dynamic>?
      setState(() {
        isLoading = false;
      });
      return data;
    } else {
      print('Document does not exist');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return null;
    }
  }

  List<Map<String, String>> items = [
    {"title": "Course Material", "description": "View course materials."},
    {"title": "Past Question", "description": "View course past questions."},
  ];

  List<Icon> icons = [
    Icon(Icons.menu_book_outlined, color: Colors.black, size: 15),
    Icon(Icons.question_answer_outlined, color: Colors.black, size: 15)
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    showCourseDetails(widget.courseId);
  }

  Future<void> showCourseDetails(String courseId) async {
    final course = await getCourseDetails(courseId);
    if (course != null) {
      setState(() {
        courseDetails = course;
      });
      print('THIS IS THE COURSE: $courseDetails');
    } else {
      print('No course found for ID: $courseId');
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
            ? Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.black, // Customize color
                    strokeWidth: 4,
                  ),
                ),
              )
            : Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        courseDetails['full_name'],
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
                              Text('${courseDetails['unit']} Units',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ],
                      )
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
                                  childAspectRatio: 1.2,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CourseMaterialScreen(
                                                  courseId: widget.courseId,
                                                  courseUnit:
                                                      courseDetails['unit'],
                                                  link: courseDetails[
                                                          'drive_link'] ??
                                                      'https://www.google.com/',
                                                  type: items[index]['title'] ==
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
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(10)),
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
                  padding: const EdgeInsets.all(5.0),
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
