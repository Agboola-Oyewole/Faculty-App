import 'package:faculty_app/components/exam_and_lecture_card.dart';
import 'package:faculty_app/screens/content_create_screen.dart';
import 'package:faculty_app/screens/event_screen.dart';
import 'package:faculty_app/screens/excos_page.dart';
import 'package:faculty_app/screens/profile_screen.dart';
import 'package:faculty_app/screens/resources_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  }

  // List of screens
  final List<Widget> _screens = [
    const HomeScreen(),
    const EventScreen(),
    ResourcesScreen(),
    const ProfileScreen(),
  ];

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Exit the app
          SystemNavigator.pop();
        }
      },
      child: SafeArea(
        child: Container(
          height: double.infinity, // Full screen height
          width: double.infinity, // Full screen width
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                // Strong green at the top
                Color(0xffC7FFD8), // Soft green transition
                Colors.white,

                Colors.white, // Full white at the bottom
              ],
              stops: [
                0.0,
                0.7,
                1.0
              ], // Smooth transition: 20% green, then fade to white
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(color: Color(0xffC7FFD8)),
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
                                color: Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          ),
                          Text(
                            userEmail!,
                            style: TextStyle(color: Colors.black, fontSize: 12),
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
                              builder: (context) => ExamAndLectureCard(
                                    title: 'Lecture Timetable',
                                    firebaseCollection: 'exams',
                                  )));
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
            body: _screens[_currentIndex],
            // Show selected screen
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.only(
                  left: 15.0, right: 15, bottom: 20, top: 10),
              child: Material(
                elevation: 5,
                borderRadius: const BorderRadius.all(Radius.circular(35)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.black, width: 1.5),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(35),
                    ),
                  ),
                  padding: const EdgeInsets.only(
                      top: 6, bottom: 6, left: 5, right: 5),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(
                      Radius.circular(35),
                    ),
                    child: BottomNavigationBar(
                      elevation: 5,
                      backgroundColor: Colors.white,
                      currentIndex: _currentIndex,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index; // Update selected index
                        });
                      },
                      selectedLabelStyle:
                          TextStyle(fontWeight: FontWeight.w900),
                      unselectedLabelStyle:
                          TextStyle(fontWeight: FontWeight.bold),
                      selectedItemColor: Color(0xff347928),
                      unselectedItemColor: Colors.black,
                      type: BottomNavigationBarType.fixed,
                      // Keep all images visible
                      items: const [
                        BottomNavigationBarItem(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.event_available),
                          label: 'Events',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.menu_book),
                          label: 'Resources',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(Icons.person),
                          label: 'Profile',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            floatingActionButton: _currentIndex != 3
                ? Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CreateContentScreen(
                                      tabIndex: _currentIndex == 0
                                          ? 0
                                          : _currentIndex == 1
                                              ? 1
                                              : _currentIndex == 2
                                                  ? 2
                                                  : 0,
                                    )));
                      },
                      backgroundColor: const Color(0xff347928),
                      elevation: 5.0,
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
      ),
    );
  }
}
