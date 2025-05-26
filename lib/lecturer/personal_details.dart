import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class PersonalInfoScreenLecturer extends StatefulWidget {
  const PersonalInfoScreenLecturer({super.key});

  @override
  State<PersonalInfoScreenLecturer> createState() =>
      _PersonalInfoScreenLecturerState();
}

class _PersonalInfoScreenLecturerState
    extends State<PersonalInfoScreenLecturer> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  // final TextEditingController dobController = TextEditingController();
  final String? displayName = FirebaseAuth.instance.currentUser?.email;
  bool isLoading = false; // Track loading state
  bool isTokenLoading = true; // Track loading state.
  List<String> courseCodes = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkAndAddFCMToken();
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
          setState(() {
            isTokenLoading = false;
          });
        } else {
          token = await FirebaseMessaging.instance.getToken();
          setState(() {
            isTokenLoading = false;
          });
        }

        if (token != null) {
          await docRef.update({'fcmToken': token});
          print("✅ FCM Token added for user.");
        } else {
          print("❌ Failed to get FCM token.");
        }
      } else {
        setState(() {
          isTokenLoading = false;
        });
        print("ℹ️ FCM token already exists.");
      }
    } catch (e, stack) {
      print("🚨 Error in checkAndAddFCMToken: $e");
      print(stack); // optional: helps with debugging in dev builds
      setState(() {
        isTokenLoading = false;
      });
    }
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

  Future<void> updateUserDetails({
    required List<dynamic> department,
    required String username,
    required String faculty,
    required String gender,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("⚠️ No user is signed in.");
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    setState(() {
      isLoading = true;
    });

    try {
      // ✅ Safe to update
      await userRef.update({
        'department': department,
        'username': username,
        'faculty': faculty,
        'gender': gender,
        'courses': selectedCourses,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print("✅ User details updated successfully!");
    } catch (e) {
      print("❌ Error updating user details: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateUserDetailsDept({
    required dynamic department,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("⚠️ No user is signed in.");
      return;
    }

    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    setState(() {
      isLoading = true;
    });

    try {
      await userRef.update({
        'department': department,
        'updated_at': FieldValue.serverTimestamp(),
      });

      print("✅ User details updated successfully!");
    } catch (e) {
      print("❌ Error updating user details: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String? _selectedGender;

  List<dynamic> selectedDepartments = [];
  List<dynamic> selectedCourses = [];

  final List<String> departments = [
    "Architecture",
    "Building",
    "Estate Management",
    "Urban & Regional Planning",
    "Quantity Surveying",
  ];

  final List<String> levels = [
    "100 Level",
    "200 Level",
    "300 Level",
    "400 Level",
    "500 Level"
  ];

  final List<String> semester = [
    "First Semester",
    "Second Semester",
  ];

  final List<String> genders = ["Male", "Female"];
  String username = "";

  // // Function to show date picker
  // Future<void> _selectDate(BuildContext context) async {
  //   DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: DateTime.now(),
  //     firstDate: DateTime(1950),
  //     lastDate: DateTime.now(),
  //   );
  //
  //   if (pickedDate != null) {
  //     setState(() {
  //       dobController.text =
  //           DateFormat("MM/dd/yyyy").format(pickedDate); // Format date
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Exit the app
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "⚠️ Complete your details or exit the app!",
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
        }
      },
      child: isTokenLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : Scaffold(
              // appBar: AppBar(
              //   leading: IconButton(
              //     icon: const Icon(Icons.arrow_back, color: Colors.black),
              //     onPressed: () => Navigator.pop(context),
              //   ),
              //   elevation: 0,
              //   backgroundColor: Colors.transparent,
              // ),
              body: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 20, right: 20, bottom: 20, top: 85),
                  child: Form(
                    key: _formKey, // Assign form key
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Enter your personal Information",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Please fill in the form below to make it easier for us to get to know you",
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        const SizedBox(height: 20),

                        TextField(
                          onChanged: (val) => username = val,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            labelText: "Username e.g Mr Lawal",
                            border: OutlineInputBorder(),
                            labelStyle: TextStyle(color: Colors.black),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildMultiSelectDropdown(
                              'Departments', departments, selectedDepartments,
                              (val) async {
                            setState(() => selectedDepartments = val);
                            await updateUserDetailsDept(
                                department: selectedDepartments);
                            await fetchUserCourseCodes();
                          }),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildMultiSelectDropdown(
                              'Courses', courseCodes, selectedCourses, (val) {
                            setState(() => selectedCourses = val);
                          }),
                        ),

                        // Gender Dropdown
                        _buildDropdown("Gender", genders, _selectedGender,
                            (newValue) {
                          setState(() => _selectedGender = newValue);
                        }),

                        const SizedBox(height: 30),

                        // Continue Button
                        ElevatedButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate() &&
                                selectedDepartments.isNotEmpty &&
                                _selectedGender != null &&
                                username.isNotEmpty) {
                              // Proceed if all required fields are present
                              await updateUserDetails(
                                // Await the function if it's async
                                department: selectedDepartments,
                                username: username,
                                faculty: 'Environmental Sciences',
                                gender: _selectedGender!,
                              );

                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BottomNavBar()),
                                );
                              }
                            } else {
                              print({
                                username,
                                selectedCourses,
                                selectedDepartments,
                                _selectedGender
                              });
                              // Show error if any required field is null or empty
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "❌ Please complete all fields.",
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
                            }

                            print("🧾 Form submission attempted");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white, // Customize color
                                    strokeWidth: 4,
                                  ),
                                )
                              : Text('Proceed',
                                  style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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

  Widget _buildDropdown(String hint, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(
            color: Colors.black,
            width: 1.5,
          ),
        ),
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$hint is required"; // Show validation message
        }
        return null;
      },
    );
  }
}
