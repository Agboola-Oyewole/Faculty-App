import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../bottom_nav_bar.dart';
import '../components/web_download_helper_stub.dart'
    if (dart.library.html) '../components/web_download_helper.dart';
import '../main.dart';
import '../utilities/utils.dart';

class CourseMaterialScreen extends StatefulWidget {
  final String courseId;
  final String link;
  final List<dynamic> courseDept;
  final String link2;
  final String type;
  final int courseUnit;

  const CourseMaterialScreen(
      {super.key,
      required this.courseId,
      required this.courseUnit,
      required this.type,
      required this.courseDept,
      required this.link2,
      required this.link});

  @override
  State<CourseMaterialScreen> createState() => _CourseMaterialScreenState();
}

class _CourseMaterialScreenState extends State<CourseMaterialScreen> {
  bool isLoading = false;
  Map<String, bool> isDownloadLoading = {};
  late Future<List<Map<String, dynamic>>> _filesFuture;
  List<dynamic> selectedDepartments = [];

  final List<String> departments = [
    'All',
    "Architecture",
    "Building",
    "Urban & Regional Planning",
    "Estate Management",
    "Quantity Surveying"
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getFiles();
    getUserDetails();
    _filesFuture = searchCourseFilesFromFirebase(widget.courseId, widget.type);
    nameController.text = widget.link;
    selectedDepartments = widget.courseDept;
    nameController2.text = widget.link2;
    selectedUnit =
        "${widget.courseUnit} ${widget.courseUnit > 1 ? "Units" : "Unit"}";
  }

  Map<String, dynamic>? userData;

  Future<void> getUserDetails() async {
    setState(() {
      isLoading = true;
    });
    Map<String, dynamic>? fetchedData = await fetchCurrentUserDetails();
    if (fetchedData != null) {
      if (mounted) {
        setState(() {
          userData = fetchedData;
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> getFiles() async {
    List<Map<String, dynamic>> files =
        await searchCourseFilesFromFirebase(widget.courseId, widget.type);
    print(files);
  }

  final TextEditingController nameController = TextEditingController();
  final TextEditingController nameController2 = TextEditingController();
  final TextEditingController unitController = TextEditingController();

  String? selectedUnit;

  final List<String> units = [
    '0 Unit',
    '1 Unit',
    '2 Units',
    '3 Units',
    '4 Units',
  ];

  Future<List<Map<String, dynamic>>> searchCourseFilesFromFirebase(
      String input, String type) async {
    try {
      final filesRef = FirebaseFirestore.instance
          .collection('resources')
          .doc(input.trim())
          .collection('files')
          .where('document_type', isEqualTo: type.trim())
          .orderBy('date', descending: false); // 🔍 Filter added here

      final querySnapshot = await filesRef.get();

      return querySnapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    } catch (e) {
      print("Error fetching files: $e");
      return [];
    }
  }

  Future<void> deleteCourseFileByResourceId(
      String courseId, String resourceId) async {
    try {
      setState(() {
        isLoading = true;
      });
      final filesRef = FirebaseFirestore.instance
          .collection('resources')
          .doc(courseId.trim())
          .collection('files');

      final querySnapshot = await filesRef
          .where('resource_id', isEqualTo: resourceId.trim())
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final docUrl = doc['document'] ?? '';

        // 🔥 Delete from Firebase Storage if URL is valid
        if (docUrl.isNotEmpty) {
          try {
            final ref = FirebaseStorage.instance.refFromURL(docUrl);
            await ref.delete();
            print("✅ Storage file deleted.");
          } catch (e) {
            print("⚠️ Error deleting storage file: $e");
          }
        }

        // 🗑 Delete Firestore document
        await doc.reference.delete();
        print("✅ Firestore doc deleted.");
        _filesFuture =
            searchCourseFilesFromFirebase(widget.courseId, widget.type);
        setState(() {
          isLoading = false;
        });
      } else {
        print("⚠️ No matching file with resource_id: $resourceId");
      }
    } catch (e) {
      print("❌ Error during deletion: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void confirmDelete(documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete document?",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text("Are you sure you want to delete this document?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              deleteCourseFileByResourceId(widget.courseId, documentId);
              Navigator.pop(context);
            },
            child: Text("Delete",
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(documentId);
                },
                child: Text("Delete document",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> showDownloadNotification(String fileName) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'download_channel', // ✅ Unique channel ID
      'Download Notifications', // ✅ Channel name
      channelDescription: 'Shows notifications for completed downloads',
      importance: Importance.max, // ✅ Max importance
      priority: Priority.high,
      playSound: true, // ✅ Play sound
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    // 🔥 Generate a unique notification ID (use timestamp)
    int notificationId =
        DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await flutterLocalNotificationsPlugin.show(
      notificationId, // Notification ID
      'FES Connect Hub',
      '$fileName downloaded to your Downloads folder.',
      platformChannelSpecifics,
    );
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      if (kIsWeb) {
        triggerSimpleWebDownload(url, fileName);
        print("✅ Web download triggered.");
      } else {
        if (io.Platform.isAndroid) {
          if (await Permission.manageExternalStorage.isDenied) {
            var status = await Permission.manageExternalStorage.request();
            if (!status.isGranted) {
              print("❌ Storage permission denied.");
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "❌ Storage permission denied!",
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

          // Get Downloads folder
          final downloadsDir = io.Directory('/storage/emulated/0/Download');
          if (!downloadsDir.existsSync()) {
            print("❌ Downloads directory not found!");
            return;
          }

          String fullFileName = fileName ?? '';
          String savePath = "${downloadsDir.path}/$fullFileName";

          await Dio().download(url, savePath);
          print("✅ File downloaded: $savePath");

          // Force media scanner to recognize the new file
          await io.Process.run('am', [
            'broadcast',
            '-a',
            'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
            '-d',
            'file://$savePath'
          ]);

          await showDownloadNotification(fullFileName);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("✅ Downloaded: $fullFileName",
                  style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.black),
              ),
              margin: EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e, stack) {
      print("❌ Download error: $e");
      print("🧠 StackTrace: $stack");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text("❌ Download Failed", style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black),
          ),
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> openFileFromUrlWeb(String url) async {
    try {
      triggerFullWebDownload(url);
    } catch (e) {
      // Handle error appropriately
      print("Error: $e");
    }
  }

  Future<void> openFileFromUrl(BuildContext context, String url) async {
    try {
      if (kIsWeb) {
        await openFileFromUrlWeb(url);
        return;
      }

      final fileName = url.split('/').last.split('?').first;

      // Get temp directory
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$fileName";

      // Download file
      await Dio().download(url, filePath);

      // Open document using installed apps
      await OpenFilex.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ An error occurred.",
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

  Future<void> openDriveLink(url) async {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }

  Future<void> updateDriveLinksForCourse({
    required String courseCode,
    required String link,
    required String link2,
    required List<dynamic> department,
    required int unit,
    required void Function(void Function()) setModalState,
  }) async {
    final courseRef = FirebaseFirestore.instance
        .collection('resources')
        .doc(courseCode.trim());

    try {
      setModalState(() => {}); // 👈 optional: show a loading spinner
      await courseRef.update({
        'drive_link': link,
        'drive_link_2': link2,
        'department': department,
        'unit': unit,
      });
      await refreshResources();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BottomNavBar(
                  initialIndex: 1,
                )),
      );

      print("✅ Drive links updated for $courseCode.");
    } catch (e) {
      print("❌ Failed to update drive links: $e");
    } finally {
      setModalState(() => {}); // 👈 optional: remove loading spinner
    }
  }

  void showAddRoleBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push content up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 👈 Create local state inside modal
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 20),
                  child: Wrap(
                    children: [
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
                      SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 25.0, top: 5),
                        child: Center(
                            child: Text(
                          'UPDATE DETAILS FOR ${widget.courseId}',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold),
                        )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: buildMultiSelectDropdown('Department',
                            departments.sublist(1), selectedDepartments, (val) {
                          setModalState(() => selectedDepartments = val);
                        }),
                      ),
                      buildDropdown("Units", units, selectedUnit, (val) {
                        setModalState(() => selectedUnit = val);
                      }),
                      SizedBox(
                        height: 10,
                      ),
                      buildTextFormField(nameController, 'Drive Link 1'),
                      SizedBox(
                        height: 10,
                      ),
                      buildTextFormField(nameController2, 'Drive Link 2'),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: ElevatedButton(
                          onPressed: () async {
                            setModalState(() =>
                                isLoading = true); // Start loading spinner
                            await updateDriveLinksForCourse(
                              courseCode: widget.courseId,
                              link: nameController.text.trim(),
                              department: selectedDepartments,
                              unit: int.parse(selectedUnit!.split(' ')[0]),
                              link2: nameController2.text.trim(),
                              setModalState: setModalState,
                            );
                            // Pass setModalState to update UI
                            setModalState(() =>
                                isLoading = false); // Stop loading spinner
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  5), // Add border radius here
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 4,
                                  ),
                                )
                              : Text("Submit",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isLoading ? Colors.white : Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme:
            IconThemeData(color: isLoading ? Colors.black : Colors.white),
        // 👈 back button color
        title: Text(
          widget.type == 'Past Questions'
              ? 'Past Questions'
              : 'Course Materials',
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
                              style:
                                  TextStyle(color: Colors.white, fontSize: 14),
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
                            Text('${widget.courseUnit} Units',
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
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                "Missing a file? Check the link:",
                                style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (widget.link == 'null') {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "No current google drive link for this course.",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: BorderSide(color: Colors.black),
                                        ),
                                        margin: EdgeInsets.all(16),
                                        elevation: 3,
                                        duration: Duration(seconds: 3),
                                      ),
                                    );
                                  } else {
                                    final Uri url = Uri.parse(widget.link);
                                    openDriveLink(url);
                                  }
                                },
                                child: Text(
                                  "Google Drive Link",
                                  style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              widget.link2 == 'null'
                                  ? Container()
                                  : Row(
                                      children: [
                                        Text(
                                          "Link 2:",
                                          style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(
                                          width: 8,
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            final Uri url =
                                                Uri.parse(widget.link2);
                                            openDriveLink(url);
                                          },
                                          child: Text(
                                            "Google Drive Link",
                                            style: TextStyle(
                                                color: Colors.blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                              userData!['role'] != 'student'
                                  ? GestureDetector(
                                      onTap: () =>
                                          showAddRoleBottomSheet(context),
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: Text(
                                          "Update",
                                          style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  : Container(),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Expanded(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: _filesFuture,
                              // use dynamic input
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                    color: Colors.black,
                                  ));
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Text("No resources found."));
                                }

                                final files = snapshot.data!;
                                return ListView.builder(
                                  itemCount: files.length,
                                  itemBuilder: (context, index) {
                                    final file = files[index];
                                    String classId =
                                        files[index]['resource_id'];
                                    return GestureDetector(
                                        onTap: () {
                                          final url = file['document'];

                                          openFileFromUrl(context, url);
                                        },
                                        onLongPress: () {
                                          if (userData!['role'] != 'student') {
                                            showDeleteBottomSheet(
                                                context, classId);
                                          }
                                        },
                                        child:
                                            _buildScheduleCard2(file, classId));
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: .0, top: 0),
            child: Text(label),
          ),
          SizedBox(height: 5),
          DropdownButtonFormField<String>(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            value: selectedItem,
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
            ),
            isExpanded: false,
            // validator: (value) {
            //   if (value == null || value.isEmpty) {
            //     return "This field is required"; // Show validation message
            //   }
            //   return null;
            // },
            items: items
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                    )))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard2(Map<String, dynamic> material, String classId) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        borderRadius: BorderRadius.circular(5),
        elevation: 1,
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.black, width: .5)),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xffDBDBDB).withOpacity(0.5),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(5.0)),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/images/file.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${material['title']}",
                          // Lecture title
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${material['department']}  |  ${material['semester']}  |  ${material['level']}",
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
                onTap: () async {
                  String? fileUrl = material['document'];
                  if (fileUrl != null && fileUrl.isNotEmpty) {
                    setState(() {
                      isDownloadLoading[classId] = true;
                    });
                    await downloadFile(fileUrl, material['title']);
                    setState(() {
                      isDownloadLoading[classId] = false;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "❌ No file available to download.",
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
                child: Container(
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        border: Border.all(color: Colors.black, width: 1)),
                    padding: const EdgeInsets.all(5.0),
                    child: isDownloadLoading[classId] == true
                        ? Icon(Icons.more_horiz, color: Colors.black, size: 15)
                        : Icon(Icons.download, color: Colors.black, size: 15))),
          ]),
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
                            "Select up to 3 Departments",
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
                                      if (tempSelected.length < 3) {
                                        tempSelected.add(dept);
                                      }
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
                        ? "Select Departments"
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

  Widget buildTextFormField(controller, titleHint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          labelText: titleHint,
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
