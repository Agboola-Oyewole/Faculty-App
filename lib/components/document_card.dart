import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main.dart';

class DocumentCard extends StatefulWidget {
  const DocumentCard(
      {super.key,
      required this.imageText,
      required this.documentName,
      required this.documentDetail,
      required this.documentExtension,
      required this.documentSize,
      required this.date});

  final String imageText;
  final String documentName;
  final String documentDetail;
  final String documentExtension;
  final String documentSize;
  final String date;

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
  bool isLoading = false;

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
      'Download Complete ✅',
      '$fileName has been saved to Downloads 📂',
      platformChannelSpecifics,
    );
  }

  Future<void> downloadFile(
      String url, String fileName, String documentExtension) async {
    setState(() {
      isLoading = true;
    });
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

      // Get the Downloads directory
      Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        print("❌ Downloads directory not found!");
        return;
      }

      // Get the file extension properly
      String fileExtension = documentExtension;

      // Construct the final filename
      String fullFileName =
          "$fileName$fileExtension"; // Example: "Academic Calendar.pdf"

      // Define the save path
      String savePath = "${downloadsDir.path}/$fullFileName";

      // Download the file
      Dio dio = Dio();
      await dio.download(url, savePath);

      print("✅ File downloaded: $savePath");
      // ✅ Show notification when download completes
      await showDownloadNotification(fullFileName);
      print('Sent notificarion');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded: $fullFileName")),
      );
    } catch (e) {
      print("❌ Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.grey, width: 1.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
                    ),
                    padding: const EdgeInsets.all(7.0),
                    child: Image.asset(
                      widget.imageText,
                      width: 30,
                      height: 30,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.documentName,
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                      SizedBox(
                        height: 5,
                      ),
                      Text(
                        '${widget.documentSize}  |  ${widget.date}',
                        style: TextStyle(
                            color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  String? fileUrl = widget.documentDetail;
                  if (fileUrl != null && fileUrl.isNotEmpty) {
                    await downloadFile(
                        fileUrl, widget.documentName, widget.documentExtension);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("No file available to download")),
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)),
                        border: Border.all(color: Colors.black, width: 1)),
                    padding: const EdgeInsets.all(5.0),
                    child: isLoading
                        ? SizedBox(
                            width: 20, // Adjust the size as needed
                            height: 20, // Adjust the size as needed
                            child: CircularProgressIndicator(
                              color: Colors.black,
                              value: 0.3, // Progress value (0.0 - 1.0)
                              strokeWidth: 3, // Thickness of the indicator
                            ),
                          )
                        : Icon(
                            Icons.download,
                            color: Colors.black,
                            size: 22,
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
