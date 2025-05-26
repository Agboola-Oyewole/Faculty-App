import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utilities/utils.dart';

class LecturerPostScreen extends StatefulWidget {
  const LecturerPostScreen({super.key});

  @override
  State<LecturerPostScreen> createState() => _LecturerPostScreenState();
}

class _LecturerPostScreenState extends State<LecturerPostScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<String> courses = [];
  String? selectedCourse;
  String postType = 'Announcement';
  DateTime? dueDate;
  bool isLoading = false;
  bool isPostLoading = false;
  List<PlatformFile> attachedFiles = [];

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUserDetails();
    fetchCourses();
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

  Future<void> fetchCourses() async {
    final user = _auth.currentUser;
    setState(() {
      isLoading = true;
    });
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && doc['role'] == 'lecturer') {
        setState(() {
          courses = List<String>.from(doc['courses'] ?? []);
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        attachedFiles.addAll(result.files);
      });
    }
  }

  String getMimeType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String?> uploadFile(PlatformFile file, String folder) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final fileName =
          "${user.uid}_${DateTime.now().millisecondsSinceEpoch}_${file.name}";
      final ref = FirebaseStorage.instance.ref("$folder/$fileName");

      UploadTask uploadTask;

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception("File bytes are null on web platform.");
        }

        uploadTask = ref.putData(
          file.bytes!,
          SettableMetadata(contentType: getMimeType(file.name)),
        );
      } else {
        if (file.path == null) {
          throw Exception("File path is null on mobile platform.");
        }

        final fileToUpload = File(file.path!);
        uploadTask = ref.putFile(
          fileToUpload,
          SettableMetadata(contentType: getMimeType(file.name)),
        );
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("❌ Error uploading file: $e");
      return null;
    }
  }

  Future<void> _submitPost() async {
    if (selectedCourse == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Please select a course.")));
      return;
    }

    if (titleController.text.trim().isEmpty ||
        contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter both title and content.")));
      return;
    }

    if (postType == 'Assignment' && dueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please select a due date for the assignment.")));
      return;
    }

    setState(() => isPostLoading = true);

    List<Map<String, String>> uploadedFiles = [];
    for (var file in attachedFiles) {
      String? url = await uploadFile(
          file, postType == 'Announcement' ? 'announcements' : 'assignments');
      if (url != null) {
        uploadedFiles.add({'name': file.name, 'url': url});
      }
    }

    await FirebaseFirestore.instance
        .collection(
            postType == 'Announcement' ? 'announcements' : 'assignments')
        .add({
      'course': selectedCourse,
      'type': postType,
      'title': titleController.text.trim(),
      'content': contentController.text.trim(),
      'createdAt': Timestamp.now(),
      'dueDate': postType == 'Assignment' ? Timestamp.fromDate(dueDate!) : null,
      'attachments': uploadedFiles,
      'createdBy': _auth.currentUser?.uid,
      'username': userData?['username'],
      'completed': false
    });

    setState(() {
      selectedCourse = null;
      postType = 'Announcement';
      dueDate = null;
      attachedFiles.clear();
      titleController.clear();
      contentController.clear();
      isLoading = false;
      isPostLoading = false;
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Post uploaded successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Course Announcements", style: TextStyle(fontSize: 18)),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.black))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Select Course",
                      labelStyle: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w900),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: Colors.black,
                          width: 1.5,
                        ),
                      ),
                    ),
                    value: selectedCourse,
                    items: courses.map((course) {
                      return DropdownMenuItem(
                        value: course,
                        child: Text(course),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCourse = value;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Post Type:", style: TextStyle(fontSize: 16)),
                      DropdownButton<String>(
                        value: postType,
                        items: ['Announcement', 'Assignment'].map((type) {
                          return DropdownMenuItem(
                              value: type, child: Text(type));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            postType = value!;
                          });
                        },
                      ),
                    ],
                  ),
                  if (postType == 'Assignment') ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text("Due Date: ", style: TextStyle(fontSize: 16)),
                        TextButton(
                          onPressed: () async {
                            // First pick the date
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );

                            if (pickedDate != null) {
                              // Then pick the time
                              TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );

                              if (pickedTime != null) {
                                // Combine both date and time
                                DateTime fullDateTime = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );

                                setState(() {
                                  dueDate = fullDateTime;
                                });
                              }
                            }
                          },
                          child: Text(
                            dueDate != null
                                ? DateFormat('MMM d, yyyy • h:mm a')
                                    .format(dueDate!)
                                : 'Pick date & time',
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: "New post title here...",
                            hintStyle: TextStyle(fontWeight: FontWeight.bold),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Divider(height: 16, color: Colors.grey.shade300),
                        TextField(
                          controller: contentController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: "Start typing your post...",
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        onPressed: pickFiles,
                        icon: Icon(Icons.attach_file, color: Colors.white),
                        label: Text("Attach Files",
                            style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "${attachedFiles.length} file(s) selected",
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    ],
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
                      onPressed: _submitPost,
                      child: isPostLoading
                          ? SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      color: Colors.white)))
                          : Text("Publish",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
