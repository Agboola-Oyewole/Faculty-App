import 'dart:io' as io;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/web_download_helper_stub.dart'
    if (dart.library.html) '../components/web_download_helper.dart';
import '../main.dart';
import '../utilities/utils.dart';

class CourseAssignmentFileScreen extends StatefulWidget {
  final String courseId;
  final String type;
  final int courseUnit;

  const CourseAssignmentFileScreen({
    super.key,
    required this.courseId,
    required this.courseUnit,
    required this.type,
  });

  @override
  State<CourseAssignmentFileScreen> createState() =>
      _CourseAssignmentFileScreenState();
}

class _CourseAssignmentFileScreenState
    extends State<CourseAssignmentFileScreen> {
  bool isLoading = false;
  Map<String, bool> isDownloadLoading = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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

  Future<List<Map<String, dynamic>>> fetchPosts(String collectionName) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .orderBy('createdAt', descending: true)
          .where('course', isEqualTo: widget.courseId)
          .get();

      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      print('Error fetching posts from $collectionName: $e');
      return [];
    }
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate(); // Convert Timestamp to DateTime

    // Function to get the day suffix (st, nd, rd, th)
    String getDaySuffix(int day) {
      if (day >= 11 && day <= 13) return 'th';
      switch (day % 10) {
        case 1:
          return 'st';
        case 2:
          return 'nd';
        case 3:
          return 'rd';
        default:
          return 'th';
      }
    }

    final day = dateTime.day;
    final daySuffix = getDaySuffix(day);
    final month = DateFormat.MMMM().format(dateTime);
    final year = dateTime.year;
    final time = DateFormat.jm().format(dateTime); // Format time as 4:40 PM

    return '${day}${daySuffix} of $month, $year $time';
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
          widget.type == 'Assignments'
              ? 'Assignments'
              : 'Lecturer Announcements',
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
                // Ensure `postCollection` is set to either 'announcements' or 'assignments'
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 30.0, left: 20.0, right: 20.0, bottom: 0.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: fetchPosts(widget.type == 'Assignments'
                                  ? 'assignments'
                                  : 'announcements'),
                              // 👈 dynamic input here
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                      child: CircularProgressIndicator(
                                          color: Colors.black));
                                }

                                if (!snapshot.hasData ||
                                    snapshot.data!.isEmpty) {
                                  return Center(
                                      child: Text(
                                          "No ${widget.type == 'Assignments' ? 'assignments' : 'announcements'} found."));
                                }

                                final posts = snapshot.data!;
                                return ListView.builder(
                                  itemCount: posts.length,
                                  itemBuilder: (context, index) {
                                    final post = posts[index];

                                    final event = {
                                      'title': post['title'] ?? 'Untitled',
                                      'course': post['course'] ?? 'Untitled',
                                      'username':
                                          post['username'] ?? 'Untitled',
                                      'files': post['attachments'],
                                      'completed': post['completed'] ?? false,
                                      'posted':
                                          formatTimestamp(post['createdAt']),
                                      'content':
                                          post['content'] ?? 'No description.',
                                      'dueDate': post['dueDate'] == null
                                          ? ''
                                          : formatTimestamp(post['dueDate']),
                                    };

                                    return _buildEventCard(event);
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

  Widget _buildEventCard(Map<String, dynamic> event) {
    final String time = event['dueDate'] ?? '';
    final String username = event['username'] ?? '';
    final String course = event['course'] ?? '';
    final bool completed = event['completed'];
    final String title = event['title'] ?? 'Event Title';
    final String createdAt = event['posted'] ?? '';
    final List<dynamic> files = event['files'] ?? [];
    final String description =
        event['content'] ?? 'Event description goes here.';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(5)),
        border: Border.all(color: Colors.black, width: .5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.type == 'Assignments') ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Due Date",
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                            color: Colors.grey[600])),
                    SizedBox(height: 5),
                    Text(
                      time,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1A1A4D)),
                    ),
                  ],
                ),
                SizedBox(width: 15),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      course,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  widget.type == 'Assignments'
                      ? SizedBox(
                          width: 8,
                        )
                      : Container(),
                  widget.type == 'Assignments'
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            completed ? 'Ended' : "Ongoing",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: Colors.black,
                            ),
                          ),
                        )
                      : Container(),
                ],
              )
              // Event details
            ],
          ),
          SizedBox(
            height: 20,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 15),
              Text(
                description,
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 30),
          ...files.map((file) {
            return GestureDetector(
              onTap: () {
                final url = file['url'];
                if (url != null && url.isNotEmpty) {
                  openFileFromUrl(context, url);
                }
              },
              child: _buildScheduleCard2(file, file['url']),
            );
          }).toList(),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Posted by $username',
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                Text(createdAt,
                    // optional: replace with formatted createdAt
                    style:
                        TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildScheduleCard2(Map<String, dynamic> material, String id) {
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
                    padding: const EdgeInsets.all(6.0),
                    child: Image.asset(
                      'assets/images/file.png',
                      width: 10,
                      height: 10,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${material['name']}",
                          // Lecture title
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
                onTap: () async {
                  String? fileUrl = material['url'];
                  if (fileUrl != null && fileUrl.isNotEmpty) {
                    setState(() {
                      isDownloadLoading[id] = true;
                    });
                    await downloadFile(fileUrl, material['name']);
                    setState(() {
                      isDownloadLoading[id] = false;
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
                    margin: EdgeInsets.only(left: 15),
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        border: Border.all(color: Colors.black, width: 1)),
                    padding: const EdgeInsets.all(5.0),
                    child: isDownloadLoading[id] == true
                        ? Icon(Icons.more_horiz, color: Colors.black, size: 15)
                        : Icon(Icons.download, color: Colors.black, size: 15))),
          ]),
        ),
      ),
    );
  }
}
