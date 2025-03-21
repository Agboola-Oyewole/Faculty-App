import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'bottom_nav_bar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>(); // Form key for validation
  final TextEditingController dobController = TextEditingController();
  final String? displayName = FirebaseAuth.instance.currentUser?.email;
  bool isLoading = false; // Track loading state

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  Future<void> updateUserDetails({
    required String department,
    required String level,
    required String dateOfBirth,
    required String faculty,
    required String gender,
  }) async {
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
        await userRef.update({
          'department': department,
          'level': level,
          'date_of_birth': dateOfBirth,
          'faculty': faculty,
          'gender': gender,
          'updated_at': FieldValue.serverTimestamp(), // Track last update
        });

        print("✅ User details updated successfully!");
      } catch (e) {
        print("❌ Error updating user details: $e");
      } finally {
        // Stop loading after the process completes
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

  String? _selectedDepartment;
  String? _selectedLevel;
  String? _selectedGender;

  final List<String> departments = [
    "Architecture",
    "Building",
    "Estate Management",
    "Urban & Regional Planning",
    "Quantity Surveying",
  ];

  final List<String> levels = ["100", "200", "300", "400", "500"];

  final List<String> genders = ["Male", "Female"];

  // Function to show date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        dobController.text =
            DateFormat("MM/dd/yyyy").format(pickedDate); // Format date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
        // appBar: AppBar(
        //   leading: IconButton(
        //     icon: const Icon(Icons.arrow_back, color: Colors.black),
        //     onPressed: () => Navigator.pop(context),
        //   ),
        //   elevation: 0,
        //   backgroundColor: Colors.transparent,
        // ),
        body: Padding(
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
                const SizedBox(height: 30),

                // Date of Birth
                _buildDatePickerField("Date of Birth", dobController),
                const SizedBox(height: 20),

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
                _buildDropdown("Gender", genders, _selectedGender, (newValue) {
                  setState(() => _selectedGender = newValue);
                }),
                const SizedBox(height: 30),

                // Continue Button
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Form is valid, proceed
                      print("✅ Form submitted successfully");
                      print([
                        _selectedDepartment,
                        _selectedGender,
                        _selectedLevel,
                        dobController.text
                      ]);
                      await updateUserDetails(
                        // Await the function if it's async
                        department: _selectedDepartment!,
                        level: _selectedLevel!,
                        dateOfBirth: dobController.text,
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
                      : Text('Proceed', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(String hint, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      // Prevent manual input
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        suffixIcon: const Icon(Icons.calendar_today), // Calendar icon
      ),
      onTap: () => _selectDate(context),
      // Show date picker
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "$hint is required"; // Show validation message
        }
        return null;
      },
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
