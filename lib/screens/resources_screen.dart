import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/components/document_card.dart';
import 'package:faculty_app/components/filter_modal.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
    Query query;
    if (_searchQuery.isNotEmpty) {
      query = FirebaseFirestore.instance
          .collectionGroup("files")
          .orderBy("title_lower") // Requires index
          .orderBy("date", descending: true);
    } else {
      query = FirebaseFirestore.instance
          .collectionGroup("files")
          .orderBy("date", descending: true);
    }

    print("Fetching resources...");

    // Apply search query only if not empty
    if (_searchQuery.isNotEmpty) {
      query = query.startAt([_searchQuery.toLowerCase()]).endAt(
          ["${_searchQuery.toLowerCase()}\uf8ff"]);
    }

    // Apply filters (if any)
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

    return query.snapshots().map((snapshot) {
      print("Resources fetched: ${snapshot.docs.length} documents");
      return snapshot;
    });
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

  Future<void> deleteDocument(String documentId) async {
    try {
      // Reference to the post document
      DocumentReference excosRef =
          FirebaseFirestore.instance.collection('resources').doc(documentId);

      // Fetch the post data to get the image URL
      DocumentSnapshot excosSnapshot = await excosRef.get();
      if (!excosSnapshot.exists) {
        print("Post not found.");
        return;
      }

      Map<String, dynamic>? postData =
          excosSnapshot.data() as Map<String, dynamic>?;
      String? imageUrl = postData?['document'];

      // Delete the image from Firebase Storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Extract the file path from the URL
          String filePath = imageUrl
              .split('o/')[1] // Get the storage path
              .split('?')[0] // Remove query parameters
              .replaceAll('%2F', '/'); // Decode path

          await FirebaseStorage.instance.ref(filePath).delete();
          print("Document deleted successfully.");
        } catch (imageError) {
          print("Error deleting image: $imageError");
        }
      }

      // Delete the post itself
      await excosRef.delete();
      print("Post deleted successfully.");
    } catch (e) {
      print("Error deleting post: $e");
    }
  }

  void confirmDelete(documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete document?",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text("Are you sure you want to delete this document?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              deleteDocument(documentId);
              Navigator.pop(context);
            },
            child: Text("Delete",
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showDeleteBottomSheet(BuildContext context, documentId) {
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
                  backgroundColor: Color(0xff347928),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(documentId);
                },
                child: Text("Delete document",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => BottomNavBar()),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 20.0, left: 15.0, right: 15.0, bottom: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Resources',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 20),
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            style: const TextStyle(
                                color: Colors.black, fontSize: 16),
                            decoration: const InputDecoration(
                              hintText: 'Search resources',
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
                    print("Waiting for resources...");
                    return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xff347928)),
                    );
                  }

                  if (snapshot.hasError) {
                    print("Firestore error: ${snapshot.error}");
                    return const Center(
                        child: Text("Error fetching resources"));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    print("No resources found");
                    return const Center(child: Text("No resources found"));
                  }

                  print("Displaying ${snapshot.data!.docs.length} resources");

                  final docs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var resource = docs[index].data() as Map<String, dynamic>;
                      print('Resource data: $resource');

                      return FutureBuilder<List<String>>(
                        future: Future.wait([
                          getFileSize(resource["document"]),
                          getFileType(resource["document"]),
                        ]),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return DocumentCard(
                              imageText:
                                  'assets/images/document-removebg-preview.png',
                              documentName: resource["title"],
                              documentDetail: resource['document'],
                              documentExtension: '.pdf',
                              documentSize: "Loading...",
                              date: timeAgo(
                                  (resource['date'] as Timestamp).toDate()),
                            );
                          }

                          if (snapshot.hasError || snapshot.data == null) {
                            return DocumentCard(
                              imageText:
                                  'assets/images/document-removebg-preview.png',
                              documentDetail: resource['document'],
                              documentName: resource["title"],
                              documentSize: "Unknown Size",
                              documentExtension: '.pdf',
                              date: timeAgo(
                                  (resource['date'] as Timestamp).toDate()),
                            );
                          }

                          String fileSize = snapshot.data![0];
                          String fileType = snapshot.data![1];

                          Map<String, String> fileIcons = {
                            "PDF": "assets/images/pdf.png",
                            "Word": "assets/images/word.png",
                            "PowerPoint": "assets/images/powerpoint.png",
                            "Excel": "assets/images/excel.png",
                            "Image": "assets/images/image.png",
                            "Unknown":
                                "assets/images/document-removebg-preview.png"
                          };
                          Map<String, String> fileExtensions = {
                            "PDF": ".pdf",
                            "Word": ".docx",
                            "PowerPoint": ".pptx",
                            "Excel": ".xlsx",
                          };

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DocumentViewer(url: resource['document']),
                              ),
                            ),
                            // Call function on tap
                            onLongPress: () => resource['userId'] ==
                                    FirebaseAuth.instance.currentUser?.uid
                                ? showDeleteBottomSheet(
                                    context, resource['resource_id'])
                                : null,
                            child: DocumentCard(
                              imageText: fileIcons[fileType] ??
                                  'assets/images/document-removebg-preview.png',
                              documentName: resource["title"],
                              documentDetail: resource['document'],
                              documentExtension:
                                  fileExtensions[fileType] ?? '.pdf',
                              documentSize: fileSize,
                              date: timeAgo(
                                  (resource['date'] as Timestamp).toDate()),
                            ),
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

class DocumentViewer extends StatefulWidget {
  final String url;

  const DocumentViewer({super.key, required this.url});

  @override
  State<DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<DocumentViewer> {
  double progress = 0;
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Document Viewer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              webViewController?.reload();
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: () => _openInBrowser(widget.url),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri("${widget.url}/")),
            // Using direct Firebase URL
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              useHybridComposition: true,
              allowsInlineMediaPlayback: true,
              // transparentBackground: true
            ),
            onWebViewCreated: (controller) {
              webViewController = controller;
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                this.progress = progress / 100;
              });
            },
            onReceivedError: (controller, request, error) {
              _openInBrowser("${widget.url}/");
            },
            onReceivedHttpError: (controller, request, errorResponse) {
              _openInBrowser("${widget.url}/");
            },
          ),
          if (progress < 1.0) LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }

  void _openInBrowser(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open document")),
      );
    }
  }
}
