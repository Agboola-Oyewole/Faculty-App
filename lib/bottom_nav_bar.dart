import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/screens/content_create_screen.dart';
import 'package:faculty_app/screens/course_screen.dart';
import 'package:faculty_app/screens/hub_screen.dart';
import 'package:faculty_app/screens/profile_screen.dart';
import 'package:faculty_app/utilities/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  ValueNotifier<bool> isVisible = ValueNotifier(true);
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
    print('ABJDHFUFKKG');
    initCourseData(); // loads from cache or fetches
  }

  Future<void> fetchResources() async {
    setState(() {
      isLoading = true;
    });
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

        if (!data.containsKey('document') || !data.containsKey('course_code')) {
          continue;
        }

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
          double fileSizeMB = await getFileSize(fileUrl); // your own function

          if (!tempData.containsKey(courseCode)) {
            tempData[courseCode] = {'count': 0, 'size': 0.0};
          }

          tempData[courseCode]!['count'] += 1;
          tempData[courseCode]!['size'] += fileSizeMB;
        }
      }

      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String encoded = jsonEncode(tempData);
      await prefs.setString("courseData_${user.uid}", encoded);

      // Update UI
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching resources: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> initCourseData() async {
    Map<String, Map<String, dynamic>>? data = await loadCourseDataFromPrefs();

    if (mounted) {
      if (data != null) {
        setState(() {
          courseData = data;
          isLoading = false;
        });
      } else {
        await fetchResources(); // fallback if no cached data
      }
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
      CourseScreen(),
      HubScreen(),
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
          body: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is UserScrollNotification) {
                    if (scrollNotification.direction ==
                        ScrollDirection.reverse) {
                      if (_currentIndex == 2) {
                      } else if (_currentIndex == 3) {
                      } else {
                        isVisible.value = false;
                      }
                    } else if (scrollNotification.direction ==
                        ScrollDirection.forward) {
                      isVisible.value = true;
                    }
                  }
                  return false;
                },
                child: isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator(color: Color(0xff347928)))
                    : _screens[_currentIndex], // Show current screen
              ),

              // Animated Floating Navigation Bar
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: ValueListenableBuilder<bool>(
                  valueListenable: isVisible,
                  builder: (context, visible, child) {
                    return AnimatedSlide(
                      duration: Duration(milliseconds: 200),
                      offset: visible ? Offset(0, 0) : Offset(0, 1),
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 200),
                        opacity: visible ? 1.0 : 0.0,
                        child: child,
                      ),
                    );
                  },
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
                          _navItem(Icons.grid_view_rounded, 'Hub', 2),
                          _navItem(Icons.person, 'Profile', 3),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Action Button with visibility
          floatingActionButton: ValueListenableBuilder<bool>(
            valueListenable: isVisible,
            builder: (context, visible, child) {
              return AnimatedSlide(
                duration: Duration(milliseconds: 200),
                offset: visible ? Offset(0, 0) : Offset(0, 2),
                child: AnimatedOpacity(
                  duration: Duration(milliseconds: 200),
                  opacity: visible ? 1.0 : 0.0,
                  child: child,
                ),
              );
            },
            child:
                (_currentIndex != 3 && _currentIndex != 1 && _currentIndex != 2)
                    ? Padding(
                        padding: const EdgeInsets.only(
                            bottom: 85.0, left: 10, right: 10, top: 10),
                        child: FloatingActionButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CreateContentScreen(
                                  tabIndex: _currentIndex == 0
                                      ? 0
                                      : _currentIndex == 2
                                          ? 1
                                          : 0,
                                ),
                              ),
                            );
                          },
                          backgroundColor: const Color(0xff347928),
                          elevation: 4.0,
                          child: const Icon(
                            Icons.add_a_photo,
                            color: Colors.white,
                            size: 25.0,
                          ),
                        ),
                      )
                    : Container(),
          ),
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
