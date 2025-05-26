import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/lecturer/lecturer_course_screen.dart';
import 'package:faculty_app/lecturer/profile_screen.dart';
import 'package:faculty_app/screens/content_create_screen.dart';
import 'package:faculty_app/screens/course_screen.dart';
import 'package:faculty_app/screens/hub_screen.dart';
import 'package:faculty_app/screens/profile_screen.dart';
import 'package:faculty_app/utilities/utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
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
    checkAndAddFCMToken();
    getUserDetails();
    initCourseData(); // loads from cache or fetches
  }

  Future<void> checkAndAddFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await docRef.get();
      final existingToken = userDoc.data()?['fcmToken'];

      if (kIsWeb) {
        await FirebaseMessaging.instance.requestPermission();
      }

      if (existingToken == null || existingToken.toString().isEmpty) {
        String? token;

        if (kIsWeb) {
          token = await FirebaseMessaging.instance.getToken(
            vapidKey:
                'BA4nxj2rLUAyqLe9CdvClHfpVVfWLWoH1mCpNtZyIVREFrm_FHlDbV1Bke5PZixujthOIvhG7XYInHAwalmaWzA',
          );
        } else {
          token = await FirebaseMessaging.instance.getToken();
        }

        if (token != null) {
          await docRef.update({'fcmToken': token});
          print("✅ FCM Token added for user.");
        } else {
          print("❌ Failed to get FCM token.");
        }
      } else {
        print("ℹ️ FCM token already exists.");
      }
    } catch (e, stack) {
      print("🚨 Error in checkAndAddFCMToken: $e");
      print(stack); // optional: helps with debugging in dev builds
    }
  }

  Future<void> fetchResources() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;
      final userLevel = userData['level'];
      final userDepartment = userData['department'];
      final userSemester = userData['semester'];
      final userRole = userData['role'];

      if (userRole != 'lecturer') {
        final coursesSnapshot =
            await FirebaseFirestore.instance.collection('resources').get();

        Map<String, dynamic> filteredCourses = {};

        for (var doc in coursesSnapshot.docs) {
          final courseData = doc.data();
          final courseCode = doc.id;

          final courseLevel = courseData['level'];
          final courseDepartments = List<String>.from(courseData['department']);
          final courseSemester = courseData['semester'];

          final levelMatch = courseLevel == userLevel;
          final semesterMatch = courseSemester == userSemester;
          final departmentMatch = courseDepartments.contains("All") ||
              courseDepartments.contains(userDepartment);

          if (levelMatch && departmentMatch && semesterMatch) {
            final modifiedData = Map<String, dynamic>.from(courseData);
            modifiedData.updateAll((key, value) {
              if (value is Timestamp) return value.toDate().toIso8601String();
              return value;
            });

            filteredCourses[courseCode] = modifiedData;
          }
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            "courseData_${user.uid}", jsonEncode(filteredCourses));
        print('✅ Resources saved to local storage: $filteredCourses');
      } else {
        Map<String, dynamic> filteredCourses =
            await fetchLecturerCourseResources();

// Convert Firestore Timestamps to strings
        Map<String, dynamic> sanitizedCourses = {};

        filteredCourses.forEach((courseCode, courseData) {
          Map<String, dynamic> newCourseData = {};
          courseData.forEach((key, value) {
            if (value is Timestamp) {
              newCourseData[key] = value
                  .toDate()
                  .toIso8601String(); // or value.millisecondsSinceEpoch
            } else {
              newCourseData[key] = value;
            }
          });
          sanitizedCourses[courseCode] = newCourseData;
        });

        // Save to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            "courseData_${user.uid}", jsonEncode(sanitizedCourses));
        print('✅ Resources saved to local storage: $sanitizedCourses');

        print('✅ Resources saved to local storage: $filteredCourses');
      }

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

  Future<Map<String, dynamic>> fetchLecturerCourseResources() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    Map<String, dynamic> courseData = {};

    try {
      // Step 1: Get lecturer document
      DocumentSnapshot lecturerDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!lecturerDoc.exists || lecturerDoc.data() == null) {
        print("❌ Lecturer document not found.");
        return {};
      }

      final List<dynamic> courses = lecturerDoc.get('courses') ?? [];

      // Step 2: Fetch each course document from 'resources'
      for (String courseCode in courses) {
        DocumentSnapshot resourceDoc =
            await _firestore.collection('resources').doc(courseCode).get();

        if (resourceDoc.exists && resourceDoc.data() != null) {
          courseData[courseCode] = resourceDoc.data();
        }
      }

      return courseData;
    } catch (e) {
      print('🔥 Error fetching course resources: $e');
      return {};
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
      userData?['role'] == 'lecturer' ? Placeholder() : HomeScreen(),
      userData?['role'] == 'lecturer'
          ? LecturerCoursesScreen()
          : CourseScreen(),
      userData?['role'] == 'lecturer' ? Placeholder() : HubScreen(),
      userData?['role'] == 'lecturer'
          ? ProfileScreenLecturer()
          : ProfileScreen(),
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
          backgroundColor: Colors.white,
          body: Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (scrollNotification) {
                  if (scrollNotification is UserScrollNotification) {
                    if (scrollNotification.direction ==
                        ScrollDirection.reverse) {
                      // if (_currentIndex == 2) {
                      // } else {
                      //   isVisible.value = false;
                      // }
                      isVisible.value = false;
                    } else if (scrollNotification.direction ==
                        ScrollDirection.forward) {
                      isVisible.value = true;
                    }
                  }
                  return false;
                },
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: Colors.black))
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
                    borderRadius: BorderRadius.circular(5),
                    color: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.black, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 00),
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
            child: (_currentIndex != 3 &&
                    _currentIndex != 1 &&
                    _currentIndex != 2)
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
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(5), // Add border radius here
                      ),
                      elevation: 4.0,
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 23.0,
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
            color: _currentIndex == index ? Colors.grey[600] : Colors.black,
            size: _currentIndex == index ? 23 : 18,
          ),
          Text(
            label,
            style: TextStyle(
                fontWeight:
                    _currentIndex == index ? FontWeight.w900 : FontWeight.bold,
                color: _currentIndex == index ? Colors.grey[600] : Colors.black,
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}
