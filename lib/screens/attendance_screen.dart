import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class AddClassScreen extends StatefulWidget {
  const AddClassScreen({super.key});

  @override
  State<AddClassScreen> createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final TextEditingController _lecturerNameController = TextEditingController();
  final TextEditingController _courseCodeController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Location services are disabled. Please turn on your location.")),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Location permissions are permanently denied.")),
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
        _courseCodeController.text.isEmpty ||
        _selectedLevel == null ||
        _selectedDepartment == null ||
        _courseCodeController.text.isEmpty ||
        latitude == null ||
        longitude == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please complete all fields.")),
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
          'courseCode': _courseCodeController.text,
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
          SnackBar(content: Text("Class added successfully!")),
        );
      }

      _lecturerNameController.clear();
      _courseCodeController.clear();

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
          SnackBar(content: Text("❌ Error: ${e.toString()}")),
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
      appBar: AppBar(title: Text("Add Class")),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _lecturerNameController,
                decoration: InputDecoration(labelText: "Lecturer Name"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: _courseCodeController,
                decoration: InputDecoration(labelText: "Course Code"),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Latitude"),
                controller: TextEditingController(
                    text: latitude?.toString() ?? "Fetching location..."),
                enabled: false,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: "Longitude"),
                controller: TextEditingController(
                    text: longitude?.toString() ?? "Fetching location..."),
                enabled: false,
              ),
              SizedBox(height: 10),
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isLoading ? null : _addClass,
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
                    borderRadius: BorderRadius.circular(8),
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

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String studentName = "";
  String matricNo = "";
  bool isLoading = false;
  String? deviceId;

  @override
  void initState() {
    super.initState();
    getUserDetails();
    fetchDeviceId();
  }

  void fetchDeviceId() async {
    deviceId = await getDeviceId();
    print("Device ID: $deviceId");
  }

  Future<String?> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Unique Android device ID
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor; // Unique iOS device ID
    }
    return null;
  }

  Future<void> checkIn(String classId, Map<String, dynamic> venue) async {
    setState(() {
      isLoading = true;
    });

    try {
      // ✅ Get Matric ID
      if (matricNo.isEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🚫 Input your Matric Number.")),
        );
        return;
      }

      // ✅ Get Device ID
      if (deviceId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("🚫 Unable to fetch device ID!, Try again.")),
        );
        return;
      }

      // ✅ Get User's Location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // ✅ Detect Mock Location (Fake GPS)
      if (position.isMocked) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("🚨 Mock location detected! Check-in blocked.")),
        );
        return;
      }

      // ✅ Verify GPS Accuracy & Distance
      double distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        venue['lat'],
        venue['lng'],
      );

      if (distance > 50) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("❌ You are not present at the class venue!")),
        );
        return;
      }

      // ✅ Prevent VPN & Proxy Usage (Optional)
      final ipResponse = await http.get(Uri.parse('https://ipinfo.io/json'));
      final ipData = jsonDecode(ipResponse.body);
      if (ipData.containsKey("proxy") && ipData["proxy"] == true) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("🚫 VPN or Proxy detected! Check-in blocked.")),
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
          const SnackBar(content: Text("⚠️ You have already checked in.")),
        );
        return;
      }

      // ✅ Step 2: Check if Device ID Already Exists
      QuerySnapshot deviceCheck =
          await studentsCollection.where("deviceId", isEqualTo: deviceId).get();

      if (deviceCheck.docs.isNotEmpty) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text("🚨 This device has already been used for check-in!")),
        );
        return;
      }

      // ✅ Step 3: Store Check-In with Device ID
      await studentsCollection.doc(matricNo).set({
        "name": FirebaseAuth.instance.currentUser?.displayName.toString(),
        "matric_no": matricNo,
        "timestamp": FieldValue.serverTimestamp(),
        "status": "present",
        "latitude": position.latitude,
        "longitude": position.longitude,
        "deviceId": deviceId, // Ensure Device ID is stored
      });

      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Check-in successful!")),
      );
    } catch (e) {
      print("Error checking in: $e");
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Error checking in. Please try again.")),
      );
    }
  }

  Map<String, dynamic>? userData;

  Future<void> getUserDetails() async {
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (fetchedData != null) {
      setState(() {
        userData = fetchedData;
      });
    }
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
                  backgroundColor: Color(0xff347928),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Class Attendance")),
      body: Column(
        children: [
          // Student Info Input
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => studentName = val,
                  decoration: InputDecoration(labelText: "Full Name"),
                  controller: TextEditingController(
                      text: FirebaseAuth.instance.currentUser?.displayName
                              .toString() ??
                          "Fetching location..."),
                  enabled: false,
                ),
                TextField(
                  onChanged: (val) => matricNo = val,
                  decoration: InputDecoration(labelText: "Matric Number"),
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
                      isEqualTo:
                          userData?['department']) // 🔹 Filter by department
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No classes available for your level & department.",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  );
                }

                var classes = snapshot.data!.docs;

                return Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      var classData =
                          classes[index].data() as Map<String, dynamic>;
                      String classId = classes[index].id;
                      var metadata = classData['metadata'];

                      return GestureDetector(
                        onLongPress: () {
                          showDeleteBottomSheet(context, metadata['classId']);
                        },
                        child: Card(
                          child: ListTile(
                            title:
                                Text("Lecturer: ${metadata['lecturer_name']}"),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      "Course Code: ${metadata['courseCode']}"),
                                  SizedBox(height: 5),
                                  Text("Date: ${metadata['date']}"),
                                  SizedBox(height: 5),
                                  Text(
                                    "Google Sheets Link: ",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  SelectableText(
                                    "${metadata['sheetUrl'] ?? 'No link generated.'}",
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => metadata['completed']
                                  ? null
                                  : checkIn(classId, metadata['venue']),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white, // Customize color
                                        strokeWidth: 4,
                                      ),
                                    )
                                  : Text(
                                      metadata['completed']
                                          ? 'Ended'
                                          : "Check In",
                                      style: TextStyle(
                                          color: metadata['completed']
                                              ? Colors.grey
                                              : Colors.black),
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
