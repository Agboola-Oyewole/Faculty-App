import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/components/post_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _posts = [];
  Map<String, Map<String, dynamic>> _userCache = {};
  bool _isLoading = true;
  String? currentUser;

  @override
  void initState() {
    super.initState();
    _fetchPosts(); // Load posts when the screen initializes
    currentUser = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);

    try {
      QuerySnapshot postSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> posts = postSnapshot.docs.map((doc) {
        return {
          ...doc.data() as Map<String, dynamic>,
          'postId': doc.id,
        };
      }).toList();

      setState(() {
        _posts = posts;
        _isLoading = false;
      });

      _fetchUserData(posts);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print("Error fetching posts: $e");
    }
  }

  Future<void> _fetchUserData(List<Map<String, dynamic>> posts) async {
    for (var post in posts) {
      String userId = post['userId'];

      if (!_userCache.containsKey(userId)) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userSnapshot.exists) {
          setState(() {
            _userCache[userId] = userSnapshot.data() as Map<String, dynamic>;
          });
        }
      }
    }
  }

  Future<void> _refreshPosts() async {
    await _fetchPosts();
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
      padding:
          const EdgeInsets.only(top: 20.0, left: 0.0, right: 0.0, bottom: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // GestureDetector(
                  //   onTap: () {
                  //     Scaffold.of(context).openDrawer();
                  //   },
                  //   child: Container(
                  //     decoration: BoxDecoration(
                  //         color: Colors.white60,
                  //         borderRadius:
                  //             const BorderRadius.all(Radius.circular(10.0)),
                  //         border: Border.all(color: Colors.black, width: 1)),
                  //     padding: const EdgeInsets.all(10.0),
                  //     child: const Icon(
                  //       Icons.menu,
                  //       color: Colors.black,
                  //       size: 18,
                  //     ),
                  //   ),
                  // ),
                  SizedBox(width: 5),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text(
                      'FES Connect Hub',
                      style:
                          TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                    ),
                  ),
                ],
              ),
              // GestureDetector(
              //   onTap: () {
              //     Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //             builder: (context) => NotificationsScreen()));
              //   },
              //   child: Container(
              //     decoration: BoxDecoration(
              //         color: Colors.transparent,
              //         borderRadius:
              //             const BorderRadius.all(Radius.circular(10.0)),
              //         border: Border.all(color: Colors.black, width: 1)),
              //     padding: const EdgeInsets.all(8.0),
              //     child: Stack(
              //       clipBehavior: Clip.none,
              //       children: [
              //         const Icon(
              //           Icons.notifications_none_rounded,
              //           color: Colors.black,
              //           size: 25,
              //         ),
              //         Positioned(
              //           top: 0,
              //           right: 0,
              //           child: Container(
              //             padding: const EdgeInsets.all(4),
              //             decoration: BoxDecoration(
              //               color: Colors.red,
              //               shape: BoxShape.circle,
              //             ),
              //             constraints: const BoxConstraints(
              //               minWidth: 10,
              //               minHeight: 10,
              //             ),
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // )
            ],
          ),
          SizedBox(height: 15),
          Container(color: Colors.grey.withOpacity(0.5), height: 1.0),
          Expanded(
            child: RefreshIndicator(
              backgroundColor: Colors.white,
              color: Colors.black,
              onRefresh: _refreshPosts,
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                      color: Colors.black,
                    ))
                  : _posts.isEmpty
                      ? Center(child: Text('No posts available'))
                      : ListView.builder(
                          itemCount: _posts.length,
                          itemBuilder: (context, index) {
                            var postData = _posts[index];
                            String userId = postData['userId'];
                            var userData = _userCache[userId] ?? {};

                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(postData['postId'])
                                  .collection('comments')
                                  .get(),
                              builder: (context, snapshot) {
                                int commentCount = snapshot.hasData
                                    ? snapshot.data!.docs.length
                                    : 0;

                                return Column(
                                  children: [
                                    Posts(
                                      userName:
                                          userData['first_name'] ?? 'Unknown',
                                      profilePic: userData['profile_pic'] ??
                                          'assets/images/user.png',
                                      caption: postData['title'] ?? '',
                                      commentCount: commentCount.toString(),
                                      imageAspect: postData['imageAspect'],
                                      image: postData['image'] ??
                                          'assets/images/503 Error Service.png',
                                      initialLikes: postData['likes'] ?? [],
                                      initialBookmarks:
                                          postData['bookmarks'] ?? [],
                                      postTime: timeAgo(
                                          (postData['date'] as Timestamp)
                                              .toDate()),
                                      isVerified: (userData['role'] ?? false) !=
                                          'student',
                                      postId: postData['postId'],
                                      posterId: postData['userId'],
                                      currentUserId: currentUser!,
                                    ),
                                    Container(
                                        color: Colors.grey.withOpacity(0.5),
                                        height: 1.0),
                                  ],
                                );
                              },
                            );
                          },
                        ),
            ),
          )
        ],
      ),
    );
  }
}
