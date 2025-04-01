import 'package:flutter/material.dart';

class FolderCard extends StatelessWidget {
  final String courseCode;
  final int fileCount;
  final double totalSize; // Size in MB

  const FolderCard({
    super.key,
    required this.courseCode,
    required this.fileCount,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xffDBDBDB),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                width: 40,
                height: 40,
                'assets/images/folder-removebg-preview.png',
              ),
              SizedBox(height: 10),
              Text(
                '$courseCode Folder',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                '$fileCount ${fileCount > 1 ? 'Files' : 'File'}   •   ${totalSize.toStringAsFixed(2)}MB',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
