import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'lecturer_course_details.dart';

class EnrolledStudentsScreen extends StatefulWidget {
  final String courseId;
  final String name;
  final int unit;

  const EnrolledStudentsScreen(
      {super.key,
      required this.courseId,
      required this.unit,
      required this.name});

  @override
  State<EnrolledStudentsScreen> createState() => _EnrolledStudentsScreenState();
}

class _EnrolledStudentsScreenState extends State<EnrolledStudentsScreen> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchStudentsAndNavigate(context, widget.courseId);
  }

  void fetchStudentsAndNavigate(BuildContext context, String courseId) async {
    setState(() => isLoading = true);

    try {
      DocumentSnapshot courseDoc = await FirebaseFirestore.instance
          .collection('resources')
          .doc(courseId)
          .get();

      Map<String, dynamic> course = courseDoc.data() as Map<String, dynamic>;

      List<Map<String, dynamic>> fetchedStudents = await getStudentsForCourse(
        courseDepartments: List<String>.from(course['department']),
        courseLevel: course['level'],
        courseSemester: course['semester'],
      );

      setState(() {
        students = fetchedStudents;
        isLoading = false;
      });

      print(students);
    } catch (e) {
      print("❌ Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> getStudentsForCourse({
    required List<String> courseDepartments,
    required String courseLevel,
    required String courseSemester,
  }) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isNotEqualTo: 'lecturer')
          .get();

      List<Map<String, dynamic>> filteredStudents = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final studentDept = data['department'];
        final studentLevel = data['level'];
        final studentSemester = data['semester'];

        if (courseDepartments.contains(studentDept) &&
            studentLevel == courseLevel &&
            studentSemester == courseSemester) {
          filteredStudents.add({
            'name': '${data['first_name']} ${data['last_name']}',
            'department': studentDept,
            'level': studentLevel,
            'matric': data['matricNo'],
          });
        }
      }

      // 🔥 Sort by department, then by matric number (ascending)
      filteredStudents.sort((a, b) {
        final deptCompare = a['department'].compareTo(b['department']);
        if (deptCompare != 0) return deptCompare;

        // Convert matric to int if it's stored as string
        final int matricA = int.tryParse(a['matric'].toString()) ?? 0;
        final int matricB = int.tryParse(b['matric'].toString()) ?? 0;

        return matricA.compareTo(matricB);
      });

      return filteredStudents;
    } catch (e) {
      print("❌ Error getting students: $e");
      return [];
    }
  }

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
                  builder: (context) => LecturerCourseDetails(
                        courseId: widget.courseId,
                        name: widget.name,
                        unit: widget.unit,
                      )));
        }
      },
      child: Scaffold(
        backgroundColor: isLoading ? Colors.white : Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme:
              IconThemeData(color: isLoading ? Colors.black : Colors.white),
          // 👈 back button color
          title: Text(
            'Enrolled Students',
            style: TextStyle(
                color: isLoading ? Colors.black : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18),
          ),
        ),
        body: isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Colors.black, // Customize color
                  strokeWidth: 4,
                ),
              )
            : Column(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.menu_book_outlined,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                '${widget.courseId}    ',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            ],
                          ),
                          Text('|    ',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12)),
                          Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.white,
                                size: 15,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text('${widget.unit} Units',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 14)),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(15),
                              topRight: Radius.circular(15))),
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 30.0, left: 20.0, right: 20.0, bottom: 0.0),
                        child: students.isEmpty
                            ? const Center(child: Text("No students found"))
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 50.0),
                                    child: DataTable(
                                      columnSpacing: 30,
                                      headingRowColor:
                                          MaterialStateProperty.all(
                                              Colors.grey.shade200),
                                      columns: const [
                                        DataColumn(label: Text('#')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Department')),
                                        DataColumn(label: Text('Level')),
                                        DataColumn(label: Text('Matric No')),
                                      ],
                                      rows: List.generate(students.length,
                                          (index) {
                                        final student = students[index];
                                        return DataRow(cells: [
                                          DataCell(Text(
                                              '${index + 1}')), // start index from 1
                                          DataCell(Text(student['name'])),
                                          DataCell(Text(student['department'])),
                                          DataCell(Text(student['level'])),
                                          DataCell(Text(
                                              student['matric'].toString())),
                                        ]);
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
