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
        elevation: 1,
        borderRadius: BorderRadius.circular(5),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                width: 30,
                height: 30,
                'assets/images/folder-removebg-preview.png',
              ),
              SizedBox(height: 10),
              Flexible(
                child: Text(
                  '$courseCode Folder',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
              SizedBox(height: 5),
              Text(
                '$fileCount ${fileCount > 1 ? 'Files' : 'File'}   •   ${totalSize.toStringAsFixed(2)}MB',
                style: TextStyle(color: Colors.grey[600], fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
