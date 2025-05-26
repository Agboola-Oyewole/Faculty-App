import 'package:faculty_app/lecturer/lecturer_add_materials.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class LecturerCourseDetails extends StatefulWidget {
  final String courseId;
  final int unit;
  final String name;

  const LecturerCourseDetails({
    super.key,
    required this.name,
    required this.unit,
    required this.courseId,
  });

  @override
  State<LecturerCourseDetails> createState() => _LecturerCourseDetailsState();
}

class _LecturerCourseDetailsState extends State<LecturerCourseDetails> {
  List<Map<String, String>> items = [
    {
      "title": "Enrolled Students",
      "description": "View list of students in this course."
    },
    {
      "title": "Upload Materials",
      "description": "Upload PDFs, slides, or useful resources."
    },
    {
      "title": "Add Announcements",
      "description": "Send updates or notes to your students."
    },
    {
      "title": "Take Attendance",
      "description": "Record and manage class attendance."
    },
  ];

  List<Icon> icons = [
    Icon(Icons.people_outline, color: Colors.black, size: 18),
    // Enrolled Students
    Icon(Icons.upload_file_outlined, color: Colors.black, size: 18),
    // Upload Materials
    Icon(Icons.campaign_outlined, color: Colors.black, size: 18),
    // Add Announcements
    Icon(Icons.checklist_outlined, color: Colors.black, size: 18),

    // Take Attendance
  ];

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
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: IconThemeData(color: Colors.white),
          // 👈 back button color
          title: Text(
            'Course Details',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
        body: Column(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 20,
                ),
                Text(
                  widget.name,
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
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                    Text('|    ',
                        style: TextStyle(color: Colors.white, fontSize: 12)),
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
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
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
                            childAspectRatio: kIsWeb
                                ? MediaQuery.of(context).size.width /
                                    (MediaQuery.of(context).size.height / 1.9)
                                : MediaQuery.of(context).size.width /
                                    (MediaQuery.of(context).size.height / 2.3),
                          ),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            LecturerPostScreen()));
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
