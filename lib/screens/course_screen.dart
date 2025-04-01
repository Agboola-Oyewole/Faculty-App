import 'package:faculty_app/components/folder_card.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class CourseScreen extends StatelessWidget {
  final Map<String, Map<String, dynamic>>? courseData;
  final bool isLoading;

  const CourseScreen(
      {super.key, required this.courseData, required this.isLoading});

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
                        color: Color(0xff347928),
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
                            int fileCount = courseData![courseCode]!['count'];
                            double totalSize = courseData![courseCode]!['size'];

                            return FolderCard(
                              courseCode: courseCode,
                              fileCount: fileCount,
                              totalSize: totalSize,
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
