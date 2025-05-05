import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CgpaCalculator extends StatefulWidget {
  const CgpaCalculator({super.key});

  @override
  State<CgpaCalculator> createState() => _CgpaCalculatorState();
}

class _CgpaCalculatorState extends State<CgpaCalculator> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  List<TextEditingController> unitControllers = [];
  List<String> grades = ["A", "B", "C", "D", "E", "F"];
  List<Map<String, dynamic>> courseCodes = [];
  Map<String, String> selectedCourses =
      {}; // Store selected grades for each course
  String cgpaResult = "";

  @override
  void initState() {
    super.initState();
    loadUserCourseCodes();
  }

  Future<void> loadUserCourseCodes() async {
    await fetchUserCourseCodes(); // This should populate courseCodes

    // After fetching, add a controller for each course and set its text
    for (var course in courseCodes) {
      final controller = TextEditingController(text: course['unit'].toString());
      unitControllers.add(controller);
      selectedCourses[course['code']] = 'A';
    }
    print("THIS IS SELECTED :   $selectedCourses");
    setState(() {}); // Refresh the UI
  }

  Future<void> fetchUserCourseCodes() async {
    try {
      setState(() {
        isLoading = true;
      });

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

      final coursesSnapshot =
          await FirebaseFirestore.instance.collection('resources').get();

      List<Map<String, dynamic>> filteredCourses = [];

      for (var doc in coursesSnapshot.docs) {
        final courseData = doc.data();

        final courseLevel = courseData['level'];
        final courseDepartments = List<String>.from(courseData['department']);
        final courseSemester = courseData['semester'];
        final courseUnit = courseData['unit'] ?? 0;

        final levelMatch = courseLevel == userLevel;
        final semesterMatch = courseSemester == userSemester;

        final departmentMatch = courseDepartments.contains("All") ||
            (userDepartment is List
                ? userDepartment.any((dept) => courseDepartments.contains(dept))
                : courseDepartments.contains(userDepartment));

        if (levelMatch && departmentMatch && semesterMatch) {
          filteredCourses.add({
            'code': doc.id,
            'unit': courseUnit,
          });
        }
      }
      print(filteredCourses);
      setState(() {
        courseCodes =
            filteredCourses; // courseCodes should be List<Map<String, dynamic>>
      });
    } catch (e) {
      print('❌ Error fetching course codes and units: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void calculateCGPA() {
    double totalGradePoints = 0.0;
    double totalUnits = 0.0;

    for (int i = 0; i < courseCodes.length; i++) {
      String courseCode = courseCodes[i]['code'];
      String grade = selectedCourses[courseCode] ?? '';

      double unit = double.tryParse(unitControllers[i].text) ?? 0;
      double gradePoint = 0.0;

      switch (grade) {
        case "A":
          gradePoint = 5.0;
          break;
        case "B":
          gradePoint = 4.0;
          break;
        case "C":
          gradePoint = 3.0;
          break;
        case "D":
          gradePoint = 2.0;
          break;
        case "E":
          gradePoint = 1.0;
          break;
        case "F":
          gradePoint = 0.0;
          break;
      }

      totalGradePoints += gradePoint * unit;
      totalUnits += unit;
    }

    if (totalUnits > 0) {
      setState(() {
        cgpaResult = (totalGradePoints / totalUnits).toStringAsFixed(2);
      });
    } else {
      setState(() {
        cgpaResult = "Invalid input";
      });
    }
  }

  // void addSubjectField() {
  //   setState(() {
  //     unitControllers.add(TextEditingController());
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "CGPA Calculator",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: isLoading
          ? Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.black, // Customize color
                  strokeWidth: 4,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter your subjects and grades:",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ...List.generate(courseCodes.length, (index) {
                            String courseCode = courseCodes[index]['code'];
                            int unit = courseCodes[index]['unit'];
                            print({courseCode, index});
                            print(unitControllers);
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: unitControllers[index],
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: courseCodes[index]['code'],
                                        border: OutlineInputBorder(),
                                      ),
                                      enabled: false,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter units';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selectedCourses[courseCode] ??
                                          grades[0],
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedCourses[courseCode] =
                                              newValue!;
                                        });
                                      },
                                      items: grades.map((String grade) {
                                        return DropdownMenuItem<String>(
                                          value: grade,
                                          child: Text(grade),
                                        );
                                      }).toList(),
                                      decoration: InputDecoration(
                                        labelText: "Grade for $courseCode",
                                        labelStyle:
                                            TextStyle(color: Colors.black),
                                        border: OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          borderSide: BorderSide(
                                            color: Colors.black,
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                calculateCGPA();
                              }
                            },
                            child: Text(
                              "Calculate CGPA",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            cgpaResult.isEmpty
                                ? "Your CGPA will appear here"
                                : "Your CGPA: $cgpaResult",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: cgpaResult == "Invalid input"
                                  ? Colors.red
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
