import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final TextEditingController _lecturerNameController = TextEditingController();
  double? latitude;
  double? longitude;
  bool isLoading = true;
  String? _selectedDepartment;
  String? _selectedLevel;

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

  String? _selectedCourseCode;

  List<String> courseCodes = [];

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

      Set<String> filteredCourseCodes = {};

      for (var doc in coursesSnapshot.docs) {
        final courseData = doc.data();

        final courseLevel = courseData['level'];
        final courseDepartments = List<String>.from(courseData['department']);
        final courseSemester = courseData['semester'];

        final levelMatch = courseLevel == userLevel;
        final semesterMatch = courseSemester == userSemester;

        final departmentMatch = courseDepartments.contains("All") ||
            (userDepartment is List
                ? userDepartment.any((dept) => courseDepartments.contains(dept))
                : courseDepartments.contains(userDepartment));

        if (levelMatch && departmentMatch && semesterMatch) {
          filteredCourseCodes.add(doc.id); // doc.id is courseCode
        }
      }

      setState(() {
        courseCodes = filteredCourseCodes.toList();
      });
    } catch (e) {
      print('❌ Error fetching course codes: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    fetchUserCourseCodes();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🚫 Location services are disabled. Please turn on your location.",
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
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 Location permissions are permanently denied.",
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
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      isLoading = false;
    });
  }

  Future<void> _addClass() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    if (_lecturerNameController.text.isEmpty ||
        _selectedCourseCode!.isEmpty ||
        _selectedLevel == null ||
        _selectedDepartment == null ||
        _selectedCourseCode!.isEmpty ||
        latitude == null ||
        longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ Please complete all fields.",
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
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final classRef =
          FirebaseFirestore.instance.collection('attendance').doc();

      await classRef.set({
        'metadata': {
          'lecturer_name': _lecturerNameController.text,
          // Changed from lecturer_name
          'courseCode': _selectedCourseCode,
          'classId': classRef.id,
          'level': _selectedLevel,
          'department': _selectedDepartment,
          'venue': {
            'lat': latitude,
            'lng': longitude,
          },
          "completed": false,
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Class added successfully!",
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

      _lecturerNameController.clear();
      _selectedCourseCode = null;

      if (mounted) {
        setState(() {
          isLoading = false;
        });

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AttendanceScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 ❌ Error: ${e.toString()}",
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
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "Add Class",
            style: TextStyle(fontSize: 18),
          )),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _lecturerNameController,
                cursorColor: Colors.black,
                decoration: InputDecoration(
                  labelText: "Lecturer Name",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black, fontSize: 14),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
              ),
              SizedBox(height: 15),
              _buildDropdown("Course Code", courseCodes, _selectedCourseCode,
                  (newValue) {
                setState(() => _selectedCourseCode = newValue);
              }),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: "Latitude",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                controller: TextEditingController(
                    text: latitude?.toString() ?? "Fetching location..."),
                enabled: false,
              ),
              SizedBox(height: 15),
              TextField(
                decoration: InputDecoration(
                  labelText: "Longitude",
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                controller: TextEditingController(
                    text: longitude?.toString() ?? "Fetching location..."),
                enabled: false,
              ),
              SizedBox(height: 15),
              // Department Dropdown
              _buildDropdown("Department", departments, _selectedDepartment,
                  (newValue) {
                setState(() => _selectedDepartment = newValue);
              }),
              const SizedBox(height: 15),

              // Level Dropdown
              _buildDropdown("Level", levels, _selectedLevel, (newValue) {
                setState(() => _selectedLevel = newValue);
              }),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _addClass,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
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
                    : Text('Add Class', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(
                height: 10,
              ),
              Divider(),
              Text(
                'OR',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Divider(),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AttendanceScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child:
                    Text('Join a class', style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      items: items
          .map((item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(fontSize: 14),
              )))
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String studentName = "";
  String matricNo = "";
  bool isLoading = false;
  bool isLoadingUser = false;
  String? deviceId;

  bool _showEmptyMessage = false;

  @override
  void initState() {
    super.initState();
    getUserDetails();
    _getCurrentLocation();
    // fetchDeviceId();
    // Wait for 3 seconds before showing "no data" message
    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showEmptyMessage = true;
        });
      }
    });
  }

  // void fetchDeviceId() async {
  //   deviceId = await getDeviceId();
  //   print("Device ID: $deviceId");
  // }

  // Future<String?> getDeviceId() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //
  //   if (Platform.isAndroid) {
  //     AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
  //     return androidInfo.id; // Unique Android device ID
  //   } else if (Platform.isIOS) {
  //     IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
  //     return iosInfo.identifierForVendor; // Unique iOS device ID
  //   }
  //   return null;
  // }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🚫 Location services are disabled. Please turn on your location.",
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
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 Location permissions are permanently denied.",
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
        return;
      }
    }
  }

  // ✅ Function to get a unique Device ID
  Future<String> getUniqueDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;

    // Use androidInfo.id which is a unique identifier for the device
    final rawId = '${androidInfo.id}${androidInfo.model}${androidInfo.device}';

    // Create a SHA-256 hash of the raw ID
    final bytes = utf8.encode(rawId);
    final digest = sha256.convert(bytes);

    // Save the unique ID to SharedPreferences to ensure it's persistent across app restarts
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String deviceId = prefs.getString('device_id') ?? digest.toString();

    if (prefs.getString('device_id') == null) {
      // Save the generated unique ID the first time
      await prefs.setString('device_id', deviceId);
    }

    return deviceId;
  }

  Future<void> checkIn(String classId, Map<String, dynamic> venue) async {
    setState(() {
      isLoading = true;
    });
    deviceId = await getUniqueDeviceId();
    print(deviceId);

    try {
      // ✅ Get Device ID
      if (deviceId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 Unable to fetch device ID!, Try again.",
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
        return;
      }

      Future<Position> getPrecisePosition() async {
        LocationSettings locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, // ⬅️ best GPS accuracy
          distanceFilter: 0,
        );

        return await Geolocator.getCurrentPosition(
            locationSettings: locationSettings);
      }

      // ✅ Get User's Location
      Position position = await getPrecisePosition();

      // ✅ Detect Mock Location (Fake GPS)
      if (position.isMocked) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚨 Mock location detected! Check-in blocked.",
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
        return;
      }

      // ✅ Define limits
      const double maxAllowedDistance = 70.0; // meters
      const double maxAllowedAccuracy = 100.0; // meters

      print({
        "📍 DEBUG INFO": {
          "Current Latitude": position.latitude,
          "Current Longitude": position.longitude,
          "Venue Latitude": venue['lat'],
          "Venue Longitude": venue['lng'],
          "Accuracy": position.accuracy,
        }
      });
      //
      // ✅ Check GPS accuracy first
      if (position.accuracy > maxAllowedAccuracy) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ Poor GPS accuracy. Please wait or move to an open area.",
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
        return;
      }

      // ✅ Calculate Distance
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        venue['lat'],
        venue['lng'],
      );

      print({
        "📍 DEBUG INFO": {
          "Current Latitude": position.latitude,
          "Current Longitude": position.longitude,
          "Venue Latitude": venue['lat'],
          "Venue Longitude": venue['lng'],
          "Distance": distance,
          "Accuracy": position.accuracy,
        }
      });

      // ✅ Validate Distance
      double buffer = position.accuracy <= 20 ? 15 : 70;
      if (distance > buffer) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "❌ You are too far from the venue to check in. ${distance.toStringAsFixed(1)}m",
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
        return;
      }

      // ✅ Prevent VPN & Proxy Usage (Optional)
      final ipResponse = await http.get(Uri.parse('https://ipinfo.io/json'));
      final ipData = jsonDecode(ipResponse.body);
      if (ipData.containsKey("proxy") && ipData["proxy"] == true) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 VPN or Proxy detected! Check-in blocked.",
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
        return;
      }

      // ✅ Firestore Reference
      CollectionReference studentsCollection = FirebaseFirestore.instance
          .collection('attendance')
          .doc(classId)
          .collection('students');

      // ✅ Step 1: Check if Matric Number Already Checked-In
      DocumentSnapshot matricDoc = await studentsCollection.doc(matricNo).get();
      if (matricDoc.exists) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "⚠️ This matric number is already registered.",
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
        return;
      }

      // ✅ Step 2: Check if Device ID Already Exists
      QuerySnapshot deviceCheck =
          await studentsCollection.where("deviceId", isEqualTo: deviceId).get();

      if (deviceCheck.docs.isNotEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚨 This device has already been used for check-in!",
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
        return;
      }

      // ✅ Step 3: Store Check-In with Device ID
      await studentsCollection.doc(matricNo).set({
        "name": FirebaseAuth.instance.currentUser?.displayName.toString(),
        "matric_no": matricNo,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "present",
        'department': userData!['department'],
        "latitude": position.latitude,
        "longitude": position.longitude,
        "deviceId": deviceId, // Ensure Device ID is stored
      });

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Check-in successful!",
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
      print("Error checking in: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "⚠️ Error checking in. Please try again.",
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
  }

  Map<String, dynamic>? userData;

  Future<void> getUserDetails() async {
    setState(() {
      isLoadingUser = true;
    });
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (fetchedData != null) {
      setState(() {
        userData = fetchedData;
      });
    }
    setState(() {
      matricNo = userData!['matricNo'].toString();
      isLoadingUser = false;
    });
  }

  Future<Map<String, dynamic>?> fetchCurrentUserDetails() async {
    try {
      // Get the currently signed-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("❌ No user is currently signed in.");
        return null;
      }

      // Reference to Firestore document
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print("❌ User document not found in Firestore.");
        return null;
      }

      // Return user details as a Map
      return doc.data();
    } catch (e) {
      print("❌ Error fetching user details: $e");
      return null;
    }
  }

  Future<void> endAttendance(String documentId) async {
    try {
      // Reference to the class document
      DocumentReference classRef =
          FirebaseFirestore.instance.collection('attendance').doc(documentId);

      // Fetch the document to check if it exists
      DocumentSnapshot classSnapshot = await classRef.get();
      if (!classSnapshot.exists) {
        print("Class attendance not found.");
        return;
      }

      // Update the 'completed' field inside 'metadata'
      await classRef.update({
        'metadata.completed': true, // ✅ Updating inside metadata
      });

      print("Attendance successfully ended.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Successfully ended this attendance.")),
      );
    } catch (e) {
      print("Error ending attendance: $e");
    }
  }

  void confirmDelete(documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "End Attendance",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text(
            "Are you sure you want to end this attendance?, this action can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              endAttendance(documentId);
              Navigator.pop(context);
            },
            child: Text("End",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showDeleteBottomSheet(BuildContext context, documentId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push content up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: Wrap(children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(documentId);
                },
                child: Text("End Attendance Taking",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> openGoogleSheetLink(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  Map<String, bool> _loadingStates = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "Class Attendance",
            style: TextStyle(fontSize: 18),
          )),
      body: isLoadingUser
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : Column(
              children: [
                // Student Info Input
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 15.0, horizontal: 15),
                  child: Column(
                    children: [
                      TextField(
                        onChanged: (val) => studentName = val,
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        controller: TextEditingController(
                            text: FirebaseAuth.instance.currentUser?.displayName
                                    .toString() ??
                                "Fetching name..."),
                        enabled: false,
                      ),
                      SizedBox(
                        height: 15,
                      ),
                      TextField(
                        onChanged: (val) => studentName = val,
                        cursorColor: Colors.black,
                        decoration: InputDecoration(
                          labelText: "Matric Number",
                          border: OutlineInputBorder(),
                          labelStyle: TextStyle(color: Colors.black),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.black),
                          ),
                        ),
                        controller: TextEditingController(
                            text: userData!['matricNo'].toString()),
                        enabled: false,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('attendance')
                        .where('metadata.level',
                            isEqualTo: userData?['level']) // 🔹 Filter by level
                        .where('metadata.department',
                            isEqualTo: userData?[
                                'department']) // 🔹 Filter by department
                        .orderBy('metadata.timestamp',
                            descending:
                                true) // 🔹 Order by createdAt field in descending order (most recent first)
                        .snapshots(),
                    builder: (context, snapshot) {
                      // if (snapshot.connectionState == ConnectionState.waiting) {
                      //   return Center(child: CircularProgressIndicator());
                      // }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        if (!_showEmptyMessage) {
                          return Center(
                              child: CircularProgressIndicator(
                            color: Colors.black,
                          ));
                        } else {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Center(
                              child: Text(
                                "No classes available for your level & department.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      }

                      var classes = snapshot.data!.docs;

                      return Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, left: 10, right: 10),
                        child: ListView.builder(
                          itemCount: classes.length,
                          itemBuilder: (context, index) {
                            var classData =
                                classes[index].data() as Map<String, dynamic>;
                            String classId = classes[index].id;
                            var metadata = classData['metadata'];

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15.0),
                              child: GestureDetector(
                                onLongPress: () {
                                  userData?['role'] == 'student'
                                      ? null
                                      : showDeleteBottomSheet(
                                          context, metadata['classId']);
                                },
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    side: BorderSide(
                                        color: Colors.black, width: 0.5),
                                  ),
                                  color: Colors.white,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 15.0),
                                    child: ListTile(
                                      title: Text(
                                          "Lecturer: ${metadata['lecturer_name']}"),
                                      subtitle: Padding(
                                        padding:
                                            const EdgeInsets.only(top: 15.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                "Course Code: ${metadata['courseCode']}"),
                                            SizedBox(height: 5),
                                            Text("Date: ${metadata['date']}"),
                                            SizedBox(height: 5),
                                            Text(
                                                "Department: ${metadata['department']}"),
                                            SizedBox(height: 5),
                                            Text("Level: ${metadata['level']}"),
                                            SizedBox(height: 15),
                                            Text(
                                              "Google Sheets Link: ",
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                            SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () {
                                                final Uri url = Uri.parse(
                                                    metadata['sheetUrl']);
                                                openGoogleSheetLink(url);
                                              },
                                              child: Text(
                                                "${metadata['sheetUrl'] ?? 'No link generated.'}",
                                                style: TextStyle(
                                                    color: Colors.blue),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      trailing: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          backgroundColor: Colors.black,
                                        ),
                                        onPressed: metadata['completed']
                                            ? null
                                            : () async {
                                                setState(() {
                                                  _loadingStates[classId] =
                                                      true; // Only this button loads
                                                });

                                                await checkIn(
                                                    classId, metadata['venue']);

                                                setState(() {
                                                  _loadingStates[classId] =
                                                      false;
                                                });
                                              },
                                        child: _loadingStates[classId] == true
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors
                                                      .white, // Customize color
                                                  strokeWidth: 4,
                                                ),
                                              )
                                            : Text(
                                                metadata['completed']
                                                    ? 'Ended'
                                                    : "Check In",
                                                style: TextStyle(
                                                    color: metadata['completed']
                                                        ? Colors.white
                                                        : Colors.white),
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
