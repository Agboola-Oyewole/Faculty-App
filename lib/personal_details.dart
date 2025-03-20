import 'package:flutter/material.dart';

import 'bottom_nav_bar.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final TextEditingController _dobController = TextEditingController();

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

  final List<String> genders = ["Male", "Female", "Other"];

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
              _buildTextField("MM/DD/YYYY", _dobController, isDate: true),
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
                onPressed: () {
                  // Implement validation or navigation here
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => BottomNavBar()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Continue",
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {bool isDate = false}) {
    return TextField(
      controller: controller,
      keyboardType: isDate ? TextInputType.datetime : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
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
    );
  }
}
