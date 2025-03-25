import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/components/document_card.dart';
import 'package:faculty_app/components/filter_modal.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../bottom_nav_bar.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen> {
  Map<String, dynamic>? appliedFilters;
  String _searchQuery = "";

  // Get human-readable time ago
  String timeAgo(DateTime postTime) {
    Duration difference = DateTime.now().difference(postTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else {
      return '${(difference.inDays / 365).floor()} years ago';
    }
  }

  Future<String> getFileType(String url) async {
    try {
      var response = await http.head(Uri.parse(url));

      if (response.statusCode == 200) {
        String? contentType = response.headers['content-type'];
        print(contentType);

        if (contentType != null) {
          if (contentType.contains("pdf")) return "PDF";
          if (contentType.contains("msword") ||
              contentType.contains("wordprocessingml")) {
            return "Word";
          }
          if (contentType.contains("presentation")) return "PowerPoint";
          if (contentType.contains("spreadsheet")) return "Excel";
          if (contentType.contains("image")) return "Image";
        }
      }
      return "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  // Get file size from Firebase Storage
  Future<String> getFileSize(String url) async {
    try {
      final ref = FirebaseStorage.instance.refFromURL(url);
      final metadata = await ref.getMetadata();
      double sizeInKB = metadata.size! / 1024;
      double sizeInMB = sizeInKB / 1024;

      return sizeInMB > 1
          ? "${sizeInMB.toStringAsFixed(2)} MB"
          : "${sizeInKB.toStringAsFixed(2)} KB";
    } catch (e) {
      print("Error fetching file size: $e");
      return "Unknown Size";
    }
  }

  Stream<QuerySnapshot> getResourcesStream() {
    Query query = FirebaseFirestore.instance.collection("resources");

    if (_searchQuery.isNotEmpty) {
      query = query
          .orderBy("title") // Ensure ordering before using startAt()
          .startAt([_searchQuery]).endAt(["$_searchQuery\uf8ff"]);
    }

    if (appliedFilters != null) {
      appliedFilters!.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          if (key == "sortBy") {
            if (value == "Newest First") {
              query = query.orderBy("date", descending: true);
            } else if (value == "Oldest First") {
              query = query.orderBy("date", descending: false);
            }
          } else {
            query = query.where(key, isEqualTo: value);
          }
        }
      });
    }

    // Default sorting if no sorting is applied
    if (!(appliedFilters?.containsKey("sortBy") ?? false) &&
        _searchQuery.isEmpty) {
      query = query.orderBy("date", descending: true);
    }

    return query.snapshots();
  }

  void _openFilterModal() async {
    final filters = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterModal(),
    );

    if (filters != null) {
      setState(() {
        appliedFilters = filters;
        print(appliedFilters);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BottomNavBar()),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 30.0, left: 15.0, right: 15.0, bottom: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Resources',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white60,
                      border: Border.all(color: Colors.black, width: 0.5),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15.0, vertical: 0),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: Colors.grey[600]),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(
                                color: Colors.black, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Search resources...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.trim();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _openFilterModal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10.0)),
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: const Icon(
                        Icons.filter_alt_outlined,
                        color: Colors.black,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(color: Colors.grey.withOpacity(0.5), height: 1.0),
            const SizedBox(height: 15),
            const Text('Recent files'),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: getResourcesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No resources found"));
                  }

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var resource = docs[index].data() as Map<String, dynamic>;

                      return FutureBuilder<List<String>>(
                        future: Future.wait([
                          getFileSize(resource["document"]),
                          getFileType(resource["document"]),
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return DocumentCard(
                              imageText: 'assets/images/unknown.png',
                              documentName: resource["title"],
                              documentSize: "Loading...",
                              date: timeAgo(
                                  (resource['date'] as Timestamp).toDate()),
                            );
                          }

                          if (snapshot.hasError || snapshot.data == null) {
                            return DocumentCard(
                              imageText: 'assets/images/unknown.png',
                              documentName: resource["title"],
                              documentSize: "Unknown Size",
                              date: timeAgo(
                                  (resource['date'] as Timestamp).toDate()),
                            );
                          }

                          String fileSize =
                              snapshot.data![0]; // First Future result
                          String fileType =
                              snapshot.data![1]; // Second Future result

                          // Map fileType to an asset image
                          Map<String, String> fileIcons = {
                            "PDF": "assets/images/pdf.png",
                            "Word": "assets/images/word.png",
                            "PowerPoint": "assets/images/powerpoint.png",
                            "Excel": "assets/images/excel.png",
                            "Image": "assets/images/image.png",
                            "Unknown": "assets/images/unknown.png"
                          };

                          return DocumentCard(
                            imageText: fileIcons[fileType] ??
                                'assets/images/unknown.png',
                            documentName: resource["title"],
                            documentSize: fileSize,
                            date: timeAgo(
                                (resource['date'] as Timestamp).toDate()),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
