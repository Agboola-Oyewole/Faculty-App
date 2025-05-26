import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/bottom_nav_bar.dart';
import 'package:faculty_app/screens/faqs_screen.dart';
import 'package:faculty_app/screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../screens/excos_page.dart';
import '../utilities/utils.dart';

// Profile Screen
class ProfileScreenLecturer extends StatefulWidget {
  const ProfileScreenLecturer({super.key});

  @override
  State<ProfileScreenLecturer> createState() => _ProfileScreenLecturerState();
}

class _ProfileScreenLecturerState extends State<ProfileScreenLecturer> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserDetails();
  }

  Future<void> getUserDetails() async {
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (fetchedData != null) {
      if (mounted) {
        setState(() {
          userData = fetchedData;
        });
      }
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Exit the app
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => BottomNavBar()));
        }
      },
      child: userData == null
          ? Center(
              child: CircularProgressIndicator(
              color: Colors.black,
            )) // Show loading until data loads
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                        top: 30.0, left: 15.0, right: 15.0, bottom: 0.0),
                    child: ListView(
                      children: [
                        _buildSectionTitle("Account Settings"),
                        _buildMenuItem(
                          context,
                          title: "Personal Information",
                          icon: Icons.person,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => PersonalInfoScreen()),
                          ),
                        ),
                        // _buildMenuItem(
                        //   context,
                        //   title: "Password & Security",
                        //   icon: Icons.lock,
                        //   onTap: () => Navigator.push(
                        //     context,
                        //     MaterialPageRoute(builder: (_) => SecurityScreen()),
                        //   ),
                        // ),
                        // _buildMenuItem(
                        //   context,
                        //   title: "Notifications Preferences",
                        //   icon: Icons.notifications,
                        //   onTap: () {
                        //     Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) =>
                        //                 NotificationSettingsScreen()));
                        //   },
                        // ),
                        SizedBox(
                          height: 10,
                        ),
                        _buildSectionTitle("Community Settings"),
                        _buildMenuItem(
                          context,
                          title: "Meet the Excos",
                          icon: Icons.people,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ExcosPage()));
                          },
                        ),
                        // _buildMenuItem(
                        //   context,
                        //   title: "Bookmarks",
                        //   icon: Icons.bookmark_added,
                        //   onTap: () {
                        //     Navigator.push(
                        //         context,
                        //         MaterialPageRoute(
                        //             builder: (context) => BookmarkScreen()));
                        //   },
                        // ),

                        SizedBox(
                          height: 10,
                        ),
                        _buildSectionTitle("Other"),
                        _buildMenuItem(
                          context,
                          title: "FAQ",
                          icon: Icons.help,
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FaqsScreen()));
                          },
                        ),
                        _buildMenuItem(
                          context,
                          title: "Help Center",
                          icon: Icons.support_agent,
                          onTap: () {},
                        ),
                        _buildMenuItem(
                          context,
                          title: "Logout",
                          icon: Icons.logout,
                          onTap: () {
                            signOut();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OnboardingPage1()));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    String? userDisplayName = FirebaseAuth.instance.currentUser?.displayName;
    String? userDisplayPic = FirebaseAuth.instance.currentUser?.photoURL;
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25))),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(userDisplayPic!),
          ),
          SizedBox(height: 20),
          Text(
            userDisplayName!,
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            userEmail!,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10.0, top: 5),
            child: Material(
              borderRadius: BorderRadius.circular(5),
              elevation: 1,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.black, width: .5)),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                icon,
                                size: 18,
                              ),
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Expanded(
                              child: Text(
                                title,
                                // Lecture title
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(Icons.arrow_forward_ios,
                            color: Colors.black, size: 15),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Personal Information Screen
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String? _selectedLevel;
  String? _selectedSemester;
  String? _username;
  final TextEditingController _usernameController = TextEditingController();

  bool isLoading = false; // Track loading state

  Map<String, dynamic>? userData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserDetails();
    fetchUserCourseCodes();
  }

  Future<void> fetchUserCourseCodes() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return;

      final usersData = userDoc.data()!;
      final userDepartment = usersData['department'];

      final coursesSnapshot =
          await FirebaseFirestore.instance.collection('resources').get();

      Set<String> filteredCourseCodes = {};

      for (var doc in coursesSnapshot.docs) {
        final courseData = doc.data();

        final courseDepartments = List<String>.from(courseData['department']);

        final departmentMatch = courseDepartments.contains("All") ||
            (userDepartment is List
                ? userDepartment.any((dept) => courseDepartments.contains(dept))
                : courseDepartments.contains(userDepartment));

        if (departmentMatch) {
          filteredCourseCodes.add(doc.id); // doc.id is courseCode
        }
      }

      setState(() {
        courseCodes = filteredCourseCodes.toList();
      });
    } catch (e) {
      print('❌ Error fetching course codes: $e');
    }
  }

  Future<void> getUserDetails() async {
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (fetchedData != null) {
      setState(() {
        userData = fetchedData;
        _username = userData?['username'];
        selectedDepartments = userData?['department'];
        selectedCourses = userData?['courses'];
        _usernameController.text = userData?['username'] ?? 'Not Provided';
      });
    }
  }

  Future<void> updateUserDetails({String? username}) async {
    // Get the current logged-in user
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Reference to Firestore user document
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      setState(() {
        isLoading = true; // Start loading
      });

      try {
        // Fetch existing user data from Firestore
        DocumentSnapshot userSnapshot = await userRef.get();
        Map<String, dynamic>? userData =
            userSnapshot.data() as Map<String, dynamic>?;

        if (userData == null) {
          print("⚠️ User data not found.");
          return;
        }

        String updatedUsername = username ?? userData['username'];

        await userRef.update({
          'department': selectedDepartments,
          'courses': selectedCourses,
          'username': updatedUsername,
          'updated_at': FieldValue.serverTimestamp(), // Track last update
        });

        await refreshLecturerCourseResources();

        print("✅ User details updated successfully!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ User details updated successfully!",
              style: TextStyle(color: Colors.black),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.black),
            ),
            margin: EdgeInsets.all(16),
            elevation: 3,
            duration: Duration(seconds: 3),
          ),
        );
      } catch (e) {
        print("❌ Error updating user details: $e");
      } finally {
        // Stop loading after the process completes
        getUserDetails();
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } else {
      print("⚠️ No user is signed in.");
    }
  }

  List<dynamic> selectedDepartments = [];
  List<dynamic> selectedCourses = [];
  List<String> courseCodes = [];

  final List<String> departments = [
    "Architecture",
    "Building",
    "Estate Management",
    "Urban & Regional Planning",
    "Quantity Surveying",
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
                        initialIndex: 3,
                      )));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "Personal Information",
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: Padding(
            padding: EdgeInsets.all(15.0),
            child: userData == null
                ? Center(
                    child: CircularProgressIndicator(
                    color: Colors.black,
                  )) // Show loading until data loads
                : Column(
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 40,
                              backgroundImage:
                                  userData!['profile_pic'] != null &&
                                          userData!['profile_pic'].isNotEmpty
                                      ? NetworkImage(userData!['profile_pic'])
                                      : AssetImage('assets/images/user.png')
                                          as ImageProvider,
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ??
                                  'Loading....',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 15,
                              ),
                              _buildTextField(
                                  "First Name",
                                  userData?['first_name'] ?? "Not provided",
                                  false),
                              _buildTextField(
                                  "Last Name",
                                  userData?['last_name'] ?? "Not provided",
                                  false),
                              TextField(
                                controller: _usernameController,
                                cursorColor: Colors.black,
                                decoration: InputDecoration(
                                  labelText: "Username",
                                  border: OutlineInputBorder(),
                                  labelStyle: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 12,
                              ),
                              // _buildTextField(
                              //     "Date of Birth",
                              //     userData?['date_of_birth'] ?? "Not provided",
                              //     false),
                              _buildTextField(
                                  "Faculty",
                                  userData?['faculty'] ?? "Not provided",
                                  false),
                              _buildTextField("Gender",
                                  userData?['gender'] ?? "Not provided", false),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: buildMultiSelectDropdown(
                                    'Departments',
                                    departments,
                                    selectedDepartments, (val) async {
                                  setState(() => selectedDepartments = val);
                                }),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: buildMultiSelectDropdown(
                                    'Courses', courseCodes, selectedCourses,
                                    (val) {
                                  setState(() => selectedCourses = val);
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: Size(double.infinity, 50),
                        ),
                        onPressed: () {
                          // Check if values have actually changed
                          if (userData != null &&
                              selectedDepartments == userData?['department'] &&
                              selectedCourses == userData?['courses'] &&
                              userData!['username'] ==
                                  _usernameController.text) {
                            print('⚠️ No changes detected. Skipping update.');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "⚠️ No changes made.",
                                  style: TextStyle(color: Colors.black),
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(color: Colors.black),
                                ),
                                margin: EdgeInsets.all(16),
                                elevation: 3,
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return; // Do nothing if no changes
                          }
                          updateUserDetails(
                            username: _usernameController.text,
                          );
                        },
                        child: isLoading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Please Wait',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900),
                                  ),
                                  SizedBox(
                                    width: 15,
                                  ),
                                  SizedBox(
                                      height: 21,
                                      width: 21,
                                      child: CircularProgressIndicator(
                                          color: Colors.white)),
                                ],
                              )
                            : Text("Save",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900)),
                      ),
                      SizedBox(height: 15),
                    ],
                  )),
      ),
    );
  }

  Widget buildMultiSelectDropdown(String label, List<String> options,
      List<dynamic> selectedItems, ValueChanged<List<dynamic>> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        SizedBox(height: 5),
        Container(
          width: double.infinity, // Set to full width
          child: GestureDetector(
            onTap: () async {
              final result = await showDialog<List<String>>(
                context: context,
                builder: (context) {
                  List<String> tempSelected = [...selectedItems];
                  return StatefulBuilder(
                    builder: (context, setState) {
                      return AlertDialog(
                        title: Center(
                          child: Text(
                            "Select $label",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            children: options.map((dept) {
                              return CheckboxListTile(
                                checkColor: Colors.white,
                                activeColor: Colors.black,
                                value: tempSelected.contains(dept),
                                title: Text(
                                  dept,
                                  style: TextStyle(fontSize: 15),
                                ),
                                onChanged: (isChecked) {
                                  setState(() {
                                    if (isChecked == true &&
                                        !tempSelected.contains(dept)) {
                                      tempSelected.add(dept);
                                    } else {
                                      tempSelected.remove(dept);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, null),
                            child: Text("Cancel",
                                style: TextStyle(color: Colors.black)),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(context, tempSelected),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            child: Text("OK",
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      );
                    },
                  );
                },
              );

              if (result != null) {
                onChanged(result);
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    selectedItems.isEmpty
                        ? "Select $label"
                        : selectedItems.join(', '),
                    overflow:
                        TextOverflow.ellipsis, // Ensures text doesn't overflow
                  ),
                  Icon(Icons.arrow_drop_down)
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, String value, bool enabled) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
        ),
        controller: TextEditingController(text: value),
        enabled: enabled,
      ),
    );
  }

  Widget _buildDropdown(String hint, String label, List<String> items,
      String? selectedValue, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "$hint is required"; // Show validation message
          }
          return null;
        },
      ),
    );
  }
}
