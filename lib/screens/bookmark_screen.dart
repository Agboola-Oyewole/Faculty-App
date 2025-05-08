import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';
import '../components/post_card.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  bool isLoading = false;

  Map<String, Map<String, dynamic>> _userCache = {};
  String? currentUser;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser?.uid;
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => BottomNavBar(initialIndex: 3)));
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            "Bookmarked Posts",
            style: TextStyle(fontSize: 18),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('bookmarks',
                  arrayContains: FirebaseAuth.instance.currentUser!.uid)
              .orderBy('date', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(color: Colors.black));
            }

            final posts = snapshot.data!.docs;

            if (posts.isEmpty) {
              return Center(child: Text('No bookmarks available'));
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                var postData = posts[index].data() as Map<String, dynamic>;
                String postId = posts[index].id;
                postData['postId'] = postId;

                String userId = postData['userId'];

                // Get user data from cache or fetch if missing
                if (!_userCache.containsKey(userId)) {
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get()
                      .then((doc) {
                    if (doc.exists) {
                      setState(() {
                        _userCache[userId] = doc.data() as Map<String, dynamic>;
                      });
                    }
                  });
                }

                var userData = _userCache[userId] ?? {};

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .get(),
                  builder: (context, commentSnap) {
                    int commentCount =
                        commentSnap.hasData ? commentSnap.data!.docs.length : 0;

                    return Column(
                      children: [
                        Container(
                            color: Colors.grey.withOpacity(0.5), height: 1.0),
                        Posts(
                          isBookmarkedPage: true,
                          userName: userData['username'] ??
                              userData['first_name'] ??
                              'Unknown',
                          profilePic: userData['profile_pic'] ??
                              'assets/images/user.png',
                          caption: postData['title'] ?? '',
                          commentCount: commentCount.toString(),
                          imageAspect: postData['imageAspect'],
                          image: postData['image'] ??
                              'assets/images/503 Error Service.png',
                          initialLikes: postData['likes'] ?? [],
                          initialBookmarks: postData['bookmarks'] ?? [],
                          postTime:
                              timeAgo((postData['date'] as Timestamp).toDate()),
                          isVerified: (userData['role'] ?? false) != 'student',
                          postId: postId,
                          posterId: userId,
                          currentUserId: FirebaseAuth.instance.currentUser!.uid,
                        ),
                        Container(
                            color: Colors.grey.withOpacity(0.5), height: 1.0),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
