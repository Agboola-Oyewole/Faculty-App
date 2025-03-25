import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../screens/content_create_screen.dart';

class ExamAndLectureCard extends StatefulWidget {
  final String title;
  final String firebaseCollection;

  const ExamAndLectureCard(
      {super.key, required this.title, required this.firebaseCollection});

  @override
  State<ExamAndLectureCard> createState() => _ExamAndLectureCardState();
}

class _ExamAndLectureCardState extends State<ExamAndLectureCard> {
  Future<void> downloadFile(String url, String fileName) async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.manageExternalStorage.isDenied) {
          var status = await Permission.manageExternalStorage.request();
          if (!status.isGranted) {
            print("❌ Storage permission denied.");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Permissions Denied!")),
            );
            return;
          }
        }
      }

      // Get file extension
      String fileExtension = url.split('.').last.split('?').first;
      String fullFileName = "$fileName.$fileExtension";

      // Get the app-specific directory
      Directory? dir = await getExternalStorageDirectory();
      String savePath = "${dir!.path}/$fullFileName";

      // Download the file
      Dio dio = Dio();
      await dio.download(url, savePath);

      print("✅ File downloaded: $savePath");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded: $fullFileName")),
      );
    } catch (e) {
      print("❌ Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed")),
      );
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(widget.title),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users') // Your users collection
              .doc(FirebaseAuth.instance.currentUser!.uid) // Current user
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                color: Colors.black,
              ));
            }

            // Get current user's department, level, and semester
            var userData = userSnapshot.data!;
            String department = userData['department'];
            String level = userData['level'];
            print(department);
            print(level);
            print('HOEUO');

            return StreamBuilder<QuerySnapshot>(
              stream: widget.firebaseCollection == "academic"
                  ? FirebaseFirestore.instance
                      .collection(widget.firebaseCollection)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection(widget.firebaseCollection)
                      .where('department', isEqualTo: department)
                      .where('level', isEqualTo: level)
                      .snapshots(),
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!scheduleSnapshot.hasData ||
                    scheduleSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No schedules available."));
                }

                var schedules = scheduleSnapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    var schedule = schedules[index];
                    return _buildScheduleCard(schedule);
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateContentScreen(
                            tabIndex: widget.title == 'Current Exam Schedule'
                                ? 3
                                : widget.title == 'Lecture Timetable'
                                    ? 4
                                    : widget.title ==
                                            'Current Academic Calendar'
                                        ? 5
                                        : 0,
                          )));
            },
            backgroundColor: const Color(0xff347928),
            elevation: 5.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Icon(
                Icons.add_a_photo,
                color: Colors.white,
                size: 25.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(QueryDocumentSnapshot schedule) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.firebaseCollection != 'academic'
                ? schedule['image']
                    ? Image.network(
                        schedule['image'], // Firestore image URL
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/post_image.jpg', // Firestore image URL
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                : Image.asset(
                    'assets/images/post_image.jpg', // Firestore image URL
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
          ),
          SizedBox(height: 10),
          Text(
            schedule['title'], // Lecture title
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          widget.firebaseCollection == 'academic'
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_month_outlined,
                            color: Colors.grey, size: 16),
                        SizedBox(width: 4),
                        Text(
                          "${schedule['session']}",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    GestureDetector(
                        onTap: () async {
                          String? fileUrl =
                              widget.firebaseCollection == 'academic'
                                  ? schedule['document']
                                  : schedule['image'];
                          if (fileUrl != null && fileUrl.isNotEmpty) {
                            await downloadFile(fileUrl, schedule['title']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("No file available to download")),
                            );
                          }
                        },
                        child:
                            Icon(Icons.download, color: Colors.black, size: 22))
                  ],
                )
              : Row(
                  children: [
                    Icon(Icons.class_, color: Colors.grey, size: 16),
                    SizedBox(width: 4),
                    Text(
                      "${schedule['department']}  |  ${schedule['semester']}",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
          SizedBox(height: 8),
          widget.firebaseCollection == 'academic'
              ? Container()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${schedule['level']}",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    GestureDetector(
                        onTap: () async {
                          String? fileUrl =
                              widget.firebaseCollection == 'academic'
                                  ? schedule['document']
                                  : schedule['image'];
                          if (fileUrl != null && fileUrl.isNotEmpty) {
                            await downloadFile(fileUrl, schedule['title']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text("No file available to download")),
                            );
                          }
                        },
                        child: Icon(Icons.download,
                            color: Colors.black, size: 22)),
                  ],
                ),
        ],
      ),
    );
  }
}
