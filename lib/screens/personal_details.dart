import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../bottom_nav_bar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  // final TextEditingController dobController = TextEditingController();
  final String? displayName = FirebaseAuth.instance.currentUser?.email;
  bool isLoading = false; // Track loading state

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> updateUserDetails({
    required String department,
    required String level,
    required String username,
    required String faculty,
    required String gender,
    required int matricNo,
    required String semester,
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
      // 🔍 Check if another user already has this matricNo
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('matricNo', isEqualTo: matricNo)
          .where(FieldPath.documentId, isNotEqualTo: user.uid) // Exclude self
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "❌ Matric number already exists.",
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
        return;
      }

      // ✅ Safe to update
      await userRef.update({
        'department': department,
        'level': level,
        'matricNo': matricNo,
        'username': username,
        'semester': semester,
        'faculty': faculty,
        'gender': gender,
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

  String? _selectedDepartment;
  String? _selectedSemester;
  String? _selectedLevel;
  String? _selectedGender;

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
  String matricNo = "";
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
      child: Scaffold(
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
            padding:
                const EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 85),
            child: Form(
              key: _formKey, // Assign form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Enter your personal Information",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please fill in the form below to make it easier for us to get to know you",
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.black,
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: const Text(
                          "Be sure to input the correct matric number, it can't be changed again.",
                          style: TextStyle(color: Colors.black, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    onChanged: (val) => username = val,
                    cursorColor: Colors.black,
                    decoration: InputDecoration(
                      labelText: "Username",
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  TextField(
                    onChanged: (val) => matricNo = val,
                    cursorColor: Colors.black,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Matric Number",
                      border: OutlineInputBorder(),
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 12,
                  ),

                  // // Date of Birth
                  // _buildDatePickerField("Date of Birth", dobController),
                  // const SizedBox(height: 20),

                  // Department Dropdown
                  _buildDropdown("Department", departments, _selectedDepartment,
                      (newValue) {
                    setState(() => _selectedDepartment = newValue);
                  }),
                  const SizedBox(height: 12),

                  // Level Dropdown
                  _buildDropdown("Level", levels, _selectedLevel, (newValue) {
                    setState(() => _selectedLevel = newValue);
                  }),
                  const SizedBox(height: 12),

                  // Gender Dropdown
                  _buildDropdown("Gender", genders, _selectedGender,
                      (newValue) {
                    setState(() => _selectedGender = newValue);
                  }),
                  const SizedBox(height: 12),
                  _buildDropdown("Semester", semester, _selectedSemester,
                      (newValue) {
                    setState(() => _selectedSemester = newValue);
                  }),

                  const SizedBox(height: 30),

                  // Continue Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Form is valid, proceed
                        await updateUserDetails(
                          // Await the function if it's async
                          department: _selectedDepartment!,
                          matricNo: int.parse(matricNo),
                          username: username,
                          semester: _selectedSemester!,
                          level: _selectedLevel!,
                          faculty: 'Environmental Sciences',
                          gender: _selectedGender!,
                        );

                        // Move to the next screen AFTER updating the details
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BottomNavBar()),
                          );
                        }
                      }
                      print("✅ Form not submitted successfully");
                      // // Implement validation or navigation here
                      // signOut();
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

  // Widget _buildDatePickerField(String hint, TextEditingController controller) {
  //   return TextFormField(
  //     controller: controller,
  //     readOnly: true,
  //     // Prevent manual input
  //     decoration: InputDecoration(
  //       focusedBorder: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(5),
  //         borderSide: BorderSide(
  //           color: Colors.black,
  //           width: 1.5,
  //         ),
  //       ),
  //       hintText: hint,
  //       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
  //       contentPadding:
  //           const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //       suffixIcon: const Icon(Icons.calendar_today), // Calendar icon
  //     ),
  //     onTap: () => _selectDate(context),
  //     // Show date picker
  //     validator: (value) {
  //       if (value == null || value.isEmpty) {
  //         return "$hint is required"; // Show validation message
  //       }
  //       return null;
  //     },
  //   );
  // }

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
