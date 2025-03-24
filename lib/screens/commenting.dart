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
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: EdgeInsets.only(bottom: 15, left: 15, right: 15, top: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundImage:
                                          userData['profile_pic'] != null
                                              ? NetworkImage(
                                                  userData['profile_pic'])
                                              : AssetImage(
                                                      'assets/images/user.png')
                                                  as ImageProvider,
                                    ),
                                    title: Text(
                                        userData['first_name'] ?? "Unknown"),
                                    subtitle: Text(comment['comment']),
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
                        hintText: "Write a comment...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  GestureDetector(
                    onTap: addComment,
                    child: Icon(Icons.send, color: Color(0xff347928)),
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
