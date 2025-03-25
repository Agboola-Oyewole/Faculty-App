import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Future<void> downloadFile(
      String url, String fileName, String documentExtension) async {
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
                    child: Icon(
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
