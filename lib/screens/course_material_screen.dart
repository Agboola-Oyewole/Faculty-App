import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class CourseMaterialScreen extends StatefulWidget {
  final String courseId;
  final String link;
  final String type;
  final int courseUnit;

  const CourseMaterialScreen(
      {super.key,
      required this.courseId,
      required this.courseUnit,
      required this.type,
      required this.link});

  @override
  State<CourseMaterialScreen> createState() => _CourseMaterialScreenState();
}

class _CourseMaterialScreenState extends State<CourseMaterialScreen> {
  bool isLoading = false;
  Map<String, bool> isDownloadLoading = {};
  late Future<List<Map<String, dynamic>>> _filesFuture;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getFiles();
    _filesFuture = searchCourseFilesFromFirebase(widget.courseId, widget.type);
  }

  Future<void> getFiles() async {
    List<Map<String, dynamic>> files =
        await searchCourseFilesFromFirebase(widget.courseId, widget.type);
    print(files);
  }

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
      '✅ "$fileName" downloaded to your Downloads folder.',
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
      if (Platform.isAndroid) {
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
      }

      // Get the Downloads directory
      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        print("❌ Downloads directory not found!");
        return;
      }

      // // Get the file extension properly
      // String fileExtension = path.extension(url.split('?').first);
      // if (fileExtension.isEmpty) {
      //   fileExtension = ".pdf"; // Default to PDF if no extension found
      // }
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

      // Construct the final filename
      String fullFileName =
          "$fileName${fileExtensions[fileType]}"; // Example: "Academic Calendar.pdf"

      // Define the save path
      String savePath = "${downloadsDir.path}/$fullFileName";

      // Download the file
      Dio dio = Dio();
      await dio.download(url, savePath);

      print("✅ File downloaded: $savePath");
      // ✅ Show notification when download completes
      await showDownloadNotification(fullFileName);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Downloaded: $fullFileName",
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
      print("❌ Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "❌ Download Failed",
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

  Future<void> openFileFromUrl(BuildContext context, String url) async {
    try {
      final fileName = url.split('/').last.split('?').first;

      // Get temp directory
      final dir = await getTemporaryDirectory();
      final filePath = "${dir.path}/$fileName";

      // Download file
      await Dio().download(url, filePath);

      // Check if it's an image
      if (fileName.endsWith('.png') ||
          fileName.endsWith('.jpg') ||
          fileName.endsWith('.jpeg') ||
          fileName.endsWith('.gif') ||
          fileName.endsWith('.webp')) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ImageViewerScreen(imagePath: filePath),
          ),
        );
      } else {
        // Open document using installed apps
        await OpenFilex.open(filePath);
      }
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
          ? Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.black, // Customize color
                  strokeWidth: 4,
                ),
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
                                  final Uri url = Uri.parse(widget.link);
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
