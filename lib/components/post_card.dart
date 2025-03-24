import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/screens/commenting.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Posts extends StatefulWidget {
  final String postId;
  final String posterId;
  final String image;
  final String caption;
  final String userName;
  final String profilePic;
  final List<dynamic> initialLikes;
  final List<dynamic> initialBookmarks;
  final String commentCount;
  final String postTime;
  final bool isVerified;
  final String currentUserId;

  const Posts({
    super.key,
    required this.posterId,
    required this.postId,
    required this.userName,
    required this.profilePic,
    required this.caption,
    required this.commentCount,
    required this.image,
    required this.initialLikes,
    required this.initialBookmarks,
    required this.postTime,
    required this.isVerified,
    required this.currentUserId,
  });

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  late ValueNotifier<bool> isLiked;
  late ValueNotifier<bool> isBookmarked;
  late ValueNotifier<int> likeCount;
  late ValueNotifier<int> bookmarkCount;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    isLiked = ValueNotifier(widget.initialLikes.contains(widget.currentUserId));
    isBookmarked =
        ValueNotifier(widget.initialBookmarks.contains(widget.currentUserId));
    likeCount = ValueNotifier(widget.initialLikes.length);
    bookmarkCount = ValueNotifier(widget.initialBookmarks.length);
  }

  Future<void> toggleLike() async {
    isLiked.value = !isLiked.value;
    likeCount.value += isLiked.value ? 1 : -1;

    // Delay Firestore update to prevent immediate StreamBuilder rebuild
    Future.delayed(Duration(milliseconds: 500), () {
      FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        "likes": isLiked.value
            ? FieldValue.arrayUnion([widget.currentUserId])
            : FieldValue.arrayRemove([widget.currentUserId]),
      });
    });
  }

  void addComment(String commentText) async {
    if (commentText.isEmpty) return;

    DocumentReference postRef =
        FirebaseFirestore.instance.collection('posts').doc(widget.postId);

    await postRef.collection('comments').add({
      "userId": widget.currentUserId,
      "comment": commentText,
      "timestamp": FieldValue.serverTimestamp(),
    });
  }

  void showCommentsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push content up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return CommentSection(
            postId: widget.postId,
            currentUserId: widget.currentUserId,
            profilePic: widget.profilePic,
            userName: widget.userName);
      },
    );
  }

  Future<void> toggleBookmark() async {
    isBookmarked.value = !isBookmarked.value;
    bookmarkCount.value += isBookmarked.value ? 1 : -1;

    Future.delayed(Duration(milliseconds: 500), () {
      FirebaseFirestore.instance.collection('posts').doc(widget.postId).update({
        "bookmarks": isBookmarked.value
            ? FieldValue.arrayUnion([widget.currentUserId])
            : FieldValue.arrayRemove([widget.currentUserId]),
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.grey, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Row
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 17,
                    child: ClipOval(
                        child: widget.profilePic.contains('.png')
                            ? Image.asset(
                                widget.profilePic,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              )
                            : Image.network(
                                widget.profilePic,
                                fit: BoxFit.cover,
                                width: 40,
                                height: 40,
                              )),
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  widget.userName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                                SizedBox(width: 6),
                                if (widget.isVerified)
                                  Icon(Icons.verified,
                                      color: Colors.blue, size: 15),
                              ],
                            ),
                          ],
                        ),
                        widget.currentUserId == widget.posterId
                            ? GestureDetector(
                                onTap: () {}, child: Icon(Icons.more_vert))
                            : Container()
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(height: 8),
              Image.network(
                widget.image,
                width: double.infinity,
                height: MediaQuery.of(context).size.width * 0.50,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 8),

              // Like, Comment, Bookmark
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: isLiked,
                        builder: (context, liked, _) {
                          return GestureDetector(
                            onTap: toggleLike,
                            child: Icon(
                              liked
                                  ? FontAwesomeIcons.solidHeart
                                  : FontAwesomeIcons.heart,
                              color: liked ? Colors.red : Colors.black,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 5),
                      ValueListenableBuilder<int>(
                        valueListenable: likeCount,
                        builder: (context, count, _) {
                          return Text("$count", style: TextStyle(fontSize: 13));
                        },
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => showCommentsBottomSheet(context),
                        child: Image.asset(
                            'assets/images/comment--removebg-preview.png',
                            width: 25,
                            height: 25),
                      ),
                      SizedBox(width: 5),
                      Text(widget.commentCount, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  Row(
                    children: [
                      ValueListenableBuilder<bool>(
                        valueListenable: isBookmarked,
                        builder: (context, bookmarked, _) {
                          return GestureDetector(
                            onTap: toggleBookmark,
                            child: Icon(
                              bookmarked
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: bookmarked ? Colors.blue : Colors.black,
                            ),
                          );
                        },
                      ),
                      ValueListenableBuilder<int>(
                        valueListenable: bookmarkCount,
                        builder: (context, count, _) {
                          return Text("$count", style: TextStyle(fontSize: 13));
                        },
                      )
                    ],
                  ),
                ],
              ),

              SizedBox(height: 8),
              GestureDetector(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Text(
                  _isExpanded
                      ? widget.caption
                      : widget.caption.length > 70
                          ? '${widget.caption.substring(0, 70)}... more'
                          : widget.caption,
                  style: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 5),
              Text(widget.postTime, style: TextStyle(color: Colors.grey[500])),
            ],
          ),
        ),
      ),
    );
  }
}
