import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/components/folder_card.dart';
import 'package:faculty_app/screens/course_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class CourseScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>>? courseData;
  final bool isLoading;

  const CourseScreen(
      {super.key, required this.courseData, required this.isLoading});

  @override
  State<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends State<CourseScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserDetails();
    print('This is the course ${widget.courseData}');
  }

  Future<void> getUserDetails() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }
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

  Future<Map<String, dynamic>?> fetchCurrentUserDetails() async {
    try {
      // Get the currently signed-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("❌ No user is currently signed in.");
        return null;
      }

      // Reference to Firestore document
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print("❌ User document not found in Firestore. now");
        return null;
      }

      // Return user details as a Map
      return doc.data();
    } catch (e) {
      print("❌ Error fetching user details: $e");
      return null;
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
                    borderRadius: BorderRadius.circular(16),
                    elevation: 3,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Color(0xffDBDBDB).withOpacity(0.5),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(10.0)),
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
                                      fontSize: 13),
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
            widget.isLoading
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
                : widget.courseData!.isEmpty
                    ? Expanded(child: Center(child: Text("No resources found")))
                    : Expanded(
                        child: ListView.builder(
                          itemCount: widget.courseData!.length,
                          itemBuilder: (context, index) {
                            String courseCode =
                                widget.courseData!.keys.elementAt(index);
                            int fileCount =
                                widget.courseData![courseCode]!['count'];
                            double totalSize =
                                widget.courseData![courseCode]!['size'];

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
                                fileCount: fileCount,
                                totalSize: totalSize,
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
