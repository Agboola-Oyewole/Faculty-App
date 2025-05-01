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

Future<Map<String, Map<String, dynamic>>> refreshResources() async {
  try {
    User? user = FirebaseAuth.instance.currentUser;
    print(user?.displayName);
    if (user == null) return {};

    DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
        .instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return {};

    String userLevel = doc.data()?['level'] ?? '';
    String userDepartment = doc.data()?['department'] ?? '';
    String userSemester = doc.data()?['semester'] ?? '';

    QuerySnapshot filesSnapshot =
        await FirebaseFirestore.instance.collectionGroup("files").get();

    Map<String, Map<String, dynamic>> tempData = {};

    for (var fileDoc in filesSnapshot.docs) {
      Map<String, dynamic> data = fileDoc.data() as Map<String, dynamic>;

      if (!data.containsKey('document') || !data.containsKey('course_code')) {
        continue;
      }

      String courseCode = data['course_code'] ?? 'Unknown';
      String fileUrl = data['document'];
      String resourceLevel = data['level'] ?? '';
      String resourceDepartment = data['department'] ?? '';
      String resourceSemester = data['semester'] ?? '';

      bool levelMatch = (resourceLevel == userLevel);
      bool departmentMatch =
          (resourceDepartment == userDepartment || resourceDepartment == "All");
      bool semesterMatch = (resourceSemester == userSemester);

      if (levelMatch && departmentMatch && semesterMatch) {
        double fileSizeMB = await getFileSize(fileUrl);

        if (!tempData.containsKey(courseCode)) {
          tempData[courseCode] = {'count': 0, 'size': 0.0};
        }

        tempData[courseCode]!['count'] += 1;
        tempData[courseCode]!['size'] += fileSizeMB;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(tempData);
    await prefs.setString("courseData_${user.uid}", encodedData);

    print(
        "✅ Resources refreshed and stored in SharedPreferences: $encodedData");

    return tempData;
  } catch (e) {
    print('❌ Error refreshing resources: $e');
    return {};
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
