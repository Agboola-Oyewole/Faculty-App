import 'dart:io' as io;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';

import '../main.dart';
import '../screens/content_create_screen.dart';
import 'web_download_helper_stub.dart'
    if (dart.library.html) 'web_download_helper.dart';

class ExamAndLectureCard extends StatefulWidget {
  final String title;
  final String firebaseCollection;

  const ExamAndLectureCard(
      {super.key, required this.title, required this.firebaseCollection});

  @override
  State<ExamAndLectureCard> createState() => _ExamAndLectureCardState();
}

class _ExamAndLectureCardState extends State<ExamAndLectureCard> {
  bool isLoading = false;
  String? currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser?.uid;
  }

  void confirmDelete(String scheduleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Schedule?",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text("Are you sure you want to delete this schedule?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              deletePost(scheduleId);
              Navigator.pop(context);
            },
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text("Delete",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showDeleteBottomSheet(BuildContext context, String scheduleId) {
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
                  confirmDelete(scheduleId);
                },
                child: Text("Delete Schedule",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Future<void> deletePost(String scheduleId) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Reference to the post document
      DocumentReference postRef = FirebaseFirestore.instance
          .collection(widget.title == 'Current Exam Schedule'
              ? 'exams'
              : widget.title == 'Current Lecture Timetable'
                  ? 'lectures'
                  : 'academic')
          .doc(scheduleId);

      // Fetch the post data to get the image URL
      DocumentSnapshot postSnapshot = await postRef.get();
      if (!postSnapshot.exists) {
        print("Schedule not found.");
        return;
      }

      Map<String, dynamic>? postData =
          postSnapshot.data() as Map<String, dynamic>?;
      String? imageUrl = postData?[widget.title == 'Current Exam Schedule'
          ? 'image'
          : widget.title == 'Current Lecture Timetable'
              ? 'image'
              : 'document'];

      // Delete the image from Firebase Storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Extract the file path from the URL
          String filePath = imageUrl
              .split('o/')[1] // Get the storage path
              .split('?')[0] // Remove query parameters
              .replaceAll('%2F', '/'); // Decode path

          await FirebaseStorage.instance.ref(filePath).delete();
          print("Image deleted successfully.");
        } catch (imageError) {
          print("Error deleting image: $imageError");
        }
      }

      // Delete the post itself
      await postRef.delete();
      print("Post deleted successfully.");
    } catch (e) {
      print("Error deleting post: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ExamAndLectureCard(
                      title: widget.title,
                      firebaseCollection:
                          widget.title == 'Current Exam Schedule'
                              ? 'exams'
                              : widget.title == 'Current Lecture Timetable'
                                  ? 'lectures'
                                  : 'academic',
                    )));
      }
    }
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

  Future<String> getFileType(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.head(uri);

      String? contentType = response.headers['content-type'];
      if (contentType != null) {
        if (contentType.contains("pdf")) return "PDF";
        if (contentType.contains("msword") ||
            contentType.contains("wordprocessingml")) return "Word";
        if (contentType.contains("presentation")) return "PowerPoint";
        if (contentType.contains("spreadsheet")) return "Excel";

        if (contentType.contains("image")) {
          if (contentType.contains("jpeg")) return "JPG";
          if (contentType.contains("png")) return "PNG";
          if (contentType.contains("webp")) return "WEBP";
          if (contentType.contains("gif")) return "GIF";
          return "Image"; // fallback
        }
      }

      // Fallback: check extension in URL
      String ext = path.extension(uri.path).toLowerCase();
      if (ext == ".pdf") return "PDF";
      if ([".doc", ".docx"].contains(ext)) return "Word";
      if ([".ppt", ".pptx"].contains(ext)) return "PowerPoint";
      if ([".xls", ".xlsx"].contains(ext)) return "Excel";

      if (ext == ".jpg" || ext == ".jpeg") return "JPG";
      if (ext == ".png") return "PNG";
      if (ext == ".webp") return "WEBP";
      if (ext == ".gif") return "GIF";

      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      setState(() {
        isLoading = true;
      });
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
              setState(() {
                isLoading = false;
              });
              return;
            }
          }

          // Get Downloads folder
          final downloadsDir = io.Directory('/storage/emulated/0/Download');
          if (!downloadsDir.existsSync()) {
            print("❌ Downloads directory not found!");
            return;
          }

          String fileType = await getFileType(url);
          Map<String, String> fileExtensions = {
            "PDF": ".pdf",
            "Word": ".docx",
            "PowerPoint": ".pptx",
            "Excel": ".xlsx",
            "JPG": ".jpg",
            "PNG": ".png",
            "WEBP": ".webp",
            "GIF": ".gif",
          };

          String fullFileName = "$fileName${fileExtensions[fileType] ?? ''}";
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
          setState(() {
            isLoading = false;
          });

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
      setState(() {
        isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 18),
        ),
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
              if (scheduleSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(
                  color: Colors.black,
                ));
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

                  return GestureDetector(
                      onTap: () {
                        final url = widget.firebaseCollection == 'academic'
                            ? schedule['document']
                            : schedule['image'];

                        openFileFromUrl(context, url);
                      },
                      onLongPress: () {
                        if (userData['role'] != 'student') {
                          showDeleteBottomSheet(
                              context,
                              schedule[widget.title == 'Current Exam Schedule'
                                  ? 'examId'
                                  : 'lecturesId']);
                        }
                      },
                      child: _buildScheduleCard2(schedule));
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
            print(widget.title);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateContentScreen(
                          tabIndex: widget.title == 'Current Exam Schedule'
                              ? 2
                              : widget.title == 'Current Lecture Timetable'
                                  ? 3
                                  : widget.title == 'Current Academic Calendar'
                                      ? 4
                                      : 0,
                        )));
          },
          backgroundColor: Colors.black,
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Add border radius here
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: const Icon(
              Icons.add_a_photo,
              color: Colors.white,
              size: 20.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard2(QueryDocumentSnapshot schedule) {
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
          ),
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
                          "${schedule['title']}",
                          // Lecture title
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        widget.firebaseCollection == 'academic'
                            ? Text(
                                "Session: ${schedule['session']}",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 12),
                              )
                            : Text(
                                "${schedule['department']}  |  ${schedule['semester']}  |  ${schedule['level']}",
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 10),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // GestureDetector(
            //     onTap: () async {
            //       String? fileUrl = widget.firebaseCollection == 'academic'
            //           ? schedule['document']
            //           : schedule['image'];
            //       if (fileUrl != null && fileUrl.isNotEmpty) {
            //         await downloadFile(fileUrl, schedule['title']);
            //       } else {
            //         ScaffoldMessenger.of(context).showSnackBar(
            //           SnackBar(
            //             content: Text(
            //               "❌ No file available to download.",
            //               style: TextStyle(color: Colors.black),
            //             ),
            //             behavior: SnackBarBehavior.floating,
            //             backgroundColor: Colors.white,
            //             shape: RoundedRectangleBorder(
            //               borderRadius: BorderRadius.circular(10),
            //               side: BorderSide(color: Colors.black),
            //             ),
            //             margin: EdgeInsets.all(16),
            //             elevation: 3,
            //             duration: Duration(seconds: 3),
            //           ),
            //         );
            //       }
            //     },
            //     child: Container(
            //         decoration: BoxDecoration(
            //             color: Colors.transparent,
            //             borderRadius:
            //                 const BorderRadius.all(Radius.circular(5.0)),
            //             border: Border.all(color: Colors.black, width: 1)),
            //         padding: const EdgeInsets.all(5.0),
            //         child: isLoading
            //             ? Icon(Icons.more_horiz, color: Colors.black, size: 15)
            //             : Icon(Icons.download, color: Colors.black, size: 15))),
          ]),
        ),
      ),
    );
  }
}

class ImageViewerScreen extends StatelessWidget {
  final String imagePath;

  const ImageViewerScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Image Preview")),
      body: Center(
        child: PhotoView(imageProvider: FileImage(File(imagePath))),
      ),
    );
  }
}
