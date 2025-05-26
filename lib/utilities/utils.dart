import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

Future<void> refreshResources() async {
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

      // Department match logic
      final departmentMatch = courseDepartments.contains("All") ||
          (userDepartment is List
              ? userDepartment.any((dept) => courseDepartments.contains(dept))
              : courseDepartments.contains(userDepartment));

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
    print(
        '🔁 Resources refreshed and saved to local storage: $filteredCourses');
  } catch (e) {
    print('❌ Error refreshing resources: $e');
  }
}

Future<void> refreshLecturerCourseResources() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> courseData = {};

  try {
    // Step 1: Get lecturer document
    DocumentSnapshot lecturerDoc =
    await _firestore.collection('users').doc(uid).get();

    if (!lecturerDoc.exists || lecturerDoc.data() == null) {
      print("❌ Lecturer document not found.");
      return;
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

     ;
    Map<String, dynamic> filteredCourses = courseData;

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
        "courseData_$uid", jsonEncode(sanitizedCourses));
    print('✅ Resources saved to local storage: $sanitizedCourses');

    print('✅ Resources saved to local storage: $filteredCourses');
  } catch (e) {
    print('🔥 Error fetching course resources: $e');
    return;
  }
}

Future<Map<String, dynamic>?> fetchCurrentUserDetails() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print("❌ No user is currently signed in.");
      return null;
    }

    DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      print("❌ User document not found in Firestore.");
      return null;
    }

    return doc.data();
  } catch (e) {
    print("❌ Error fetching user details: $e");
    return null;
  }
}

Future<Map<String, Map<String, dynamic>>?> loadCourseDataFromPrefs() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  String? jsonString = prefs.getString("courseData_${user.uid}");

  if (jsonString != null) {
    print("✅ Data found in SharedPreferences.");
    Map<String, dynamic> decoded = jsonDecode(jsonString);
    Map<String, Map<String, dynamic>> restoredData = {};

    decoded.forEach((key, value) {
      restoredData[key] = Map<String, dynamic>.from(value);
    });

    return restoredData;
  } else {
    print("⚠️ No cached data found.");
    return null;
  }
}
