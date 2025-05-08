import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CommentSection extends StatefulWidget {
  final String postId;
  final String currentUserId;
  final String profilePic;
  final String userName;

  const CommentSection({
    super.key,
    required this.postId,
    required this.currentUserId,
    required this.profilePic,
    required this.userName,
  });

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  TextEditingController _commentController = TextEditingController();
  bool isLoading = true;
  bool isLoadingComment = false;
  List<Map<String, dynamic>> comments = [];

  @override
  void initState() {
    super.initState();
    fetchComments();
  }

  Future<void> fetchComments() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      comments = snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
      isLoading = false;
    });
  }

  Future<void> addComment() async {
    setState(() {
      isLoadingComment = true;
    });
    String commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    await postRef.collection('comments').add({
      "userId": widget.currentUserId,
      "comment": commentText,
      "timestamp": FieldValue.serverTimestamp(),
    });

    _commentController.clear();
    fetchComments(); // Refresh comments after adding
    setState(() {
      isLoadingComment = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topRight: Radius.circular(15))),
        height: MediaQuery.of(context).size.height * 0.6,
        padding: EdgeInsets.only(bottom: 15, left: 15, right: 15, top: 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
            SizedBox(
              height: 10,
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Text("Comments",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
            Divider(),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : comments.isEmpty
                      ? Center(child: Text("No comments yet"))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, index) {
                            final comment = comments[index];

                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection(
                                      'users') // Assuming 'users' collection exists
                                  .doc(comment['userId'])
                                  .get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: Colors.grey),
                                    title: Text(comment['comment']),
                                    subtitle: Text("Loading..."),
                                  );
                                }

                                var userData = snapshot.data!.data()
                                    as Map<String, dynamic>;
                                return ListTile(
                                  leading: CircleAvatar(
                                    radius: 18,
                                    backgroundImage: userData['profile_pic'] !=
                                            null
                                        ? NetworkImage(userData['profile_pic'])
                                        : AssetImage('assets/images/user.png')
                                            as ImageProvider,
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        userData['first_name'] ?? "Unknown",
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(
                                        width: 5,
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(comment['comment']),
                                  ),
                                  trailing: Text(
                                    timeAgo((comment['timestamp'] as Timestamp)
                                        .toDate()),
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                );
                              },
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        hintText: "Write a comment...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  isLoadingComment
                      ? CircularProgressIndicator(color: Colors.black)
                      : GestureDetector(
                          onTap: addComment,
                          child: Icon(Icons.send, color: Colors.black),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
