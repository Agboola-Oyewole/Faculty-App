import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/components/exam_and_lecture_card.dart';
import 'package:faculty_app/screens/attendance_screen.dart';
import 'package:faculty_app/screens/content_create_screen.dart';
import 'package:faculty_app/screens/course_screen.dart';
import 'package:faculty_app/screens/excos_page.dart';
import 'package:faculty_app/screens/profile_screen.dart';
import 'package:faculty_app/screens/resources_screen.dart';
import 'package:faculty_app/screens/schedule_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'screens/home_screen.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int _currentIndex;
  Map<String, Map<String, dynamic>>? courseData;
  bool isLoading = true;
  String? userDisplayName = FirebaseAuth.instance.currentUser?.displayName;
  String? userDisplayPic = FirebaseAuth.instance.currentUser?.photoURL;
  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  void initState() {
    super.initState();
    _currentIndex =
        widget.initialIndex; // Set the initial index to the optional parameter
    getUserDetails();
    fetchResources(); // Fetch data once
  }

  Future<void> fetchResources() async {
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

      Map<String, Map<String, dynamic>> tempData = {};

      for (var fileDoc in filesSnapshot.docs) {
        Map<String, dynamic> data = fileDoc.data() as Map<String, dynamic>;

        if (!data.containsKey('document') || !data.containsKey('course_code'))
          continue;

        String courseCode = data['course_code'] ?? 'Unknown';
        String fileUrl = data['document'];
        String resourceLevel = data['level'] ?? '';
        String resourceDepartment = data['department'] ?? '';
        String resourceSemester = data['semester'] ?? '';

        bool levelMatch = (resourceLevel == userLevel);
        bool departmentMatch = (resourceDepartment == userDepartment ||
            resourceDepartment == "All");
        bool semesterMatch = (resourceSemester == userSemester);

        if (levelMatch && departmentMatch && semesterMatch) {
          double fileSizeMB = await getFileSize(fileUrl);

          if (!tempData.containsKey(courseCode)) {
            tempData[courseCode] = {'count': 0, 'size': 0.0};
          }

          tempData[courseCode]!['count'] += 1;
          tempData[courseCode]!['size'] += fileSizeMB;
        }
      }

      setState(() {
        courseData = tempData;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching resources: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<double> getFileSize(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      final metadata = await ref.getMetadata();
      return metadata.size! / (1024 * 1024);
    } catch (e) {
      print("Error fetching file size: $e");
      return 0.0;
    }
  }

  Map<String, dynamic>? userData;

  Future<void> getUserDetails() async {
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (mounted && fetchedData != null) {
      setState(() {
        userData = fetchedData;
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
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  final List<Widget> _screens = [];

  @override
  Widget build(BuildContext context) {
    _screens.clear();
    _screens.addAll([
      const HomeScreen(),
      CourseScreen(courseData: courseData, isLoading: isLoading),
      ResourcesScreen(),
      const ProfileScreen(),
    ]);
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Color(0xffF1EFEC),
          drawer: Drawer(
            elevation: 5,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(color: const Color(0xff347928)),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: NetworkImage(userDisplayPic!),
                        ),
                        SizedBox(height: 10),
                        Text(
                          userDisplayName!,
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          userEmail!,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Meet the Excos'),
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => ExcosPage()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.book),
                  title: Text('Current Lecture Timetable'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExamAndLectureCard(
                                  title: 'Current Lecture Timetable',
                                  firebaseCollection: 'lectures',
                                )));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('Current Academic Calender'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExamAndLectureCard(
                                  title: 'Current Academic Calendar',
                                  firebaseCollection: 'academic',
                                )));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.event),
                  title: Text('Current Exam Schedule'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ExamAndLectureCard(
                                  title: 'Current Exam Schedule',
                                  firebaseCollection: 'exams',
                                )));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.local_activity),
                  title: Row(
                    children: [
                      Text('Attendance Taking'),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Beta',
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => userData?['role'] == 'student'
                                ? AttendanceScreen()
                                : AddClassScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.timer_sharp),
                  title: Row(
                    children: [
                      Text('Lecture Schedule'),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        'Beta',
                        style: TextStyle(
                            color: Colors.blue,
                            fontSize: 9,
                            fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => WeeklyScheduleScreen()));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => BottomNavBar(
                                  initialIndex: 3,
                                )));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    signOut();
                  },
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              _screens[_currentIndex], // Show current screen

              // Floating Navigation Bar
              Positioned(
                bottom: 20, // Adjust this value for positioning
                left: 20,
                right: 20,
                child: Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _navItem(Icons.home, 'Home', 0),
                        _navItem(Icons.edit_document, 'Courses', 1),
                        _navItem(Icons.menu_book, 'Resources', 2),
                        _navItem(Icons.person, 'Profile', 3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: (_currentIndex != 3 && _currentIndex != 1)
              ? Padding(
                  padding: const EdgeInsets.only(
                      bottom: 85.0, left: 10, right: 10, top: 10),
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateContentScreen(
                            tabIndex: _currentIndex,
                          ),
                        ),
                      );
                    },
                    backgroundColor: const Color(0xff347928),
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 25.0,
                      ),
                    ),
                  ),
                )
              : Container(),
        ),
      ),
    );
  }

  // Custom Navigation Item
  Widget _navItem(IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: _currentIndex == index ? Color(0xff347928) : Colors.black,
            size: _currentIndex == index ? 25 : 20,
          ),
          Text(
            label,
            style: TextStyle(
                fontWeight:
                    _currentIndex == index ? FontWeight.w900 : FontWeight.bold,
                color:
                    _currentIndex == index ? Color(0xff347928) : Colors.black,
                fontSize: 13),
          ),
        ],
      ),
    );
  }
}
