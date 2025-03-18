import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class Posts extends StatefulWidget {
  final String image;
  final String caption;
  final String userName;
  final String profilePic;
  final String bookmarkCount;
  final String likeCount;
  final String commentCount;
  final String shareCount;
  final String postTime;
  final bool isVerified;

  const Posts(
      {super.key,
      required this.userName,
      required this.profilePic,
      required this.caption,
      required this.commentCount,
      required this.image,
      required this.bookmarkCount,
      required this.likeCount,
      required this.postTime,
      required this.isVerified,
      required this.shareCount});

  @override
  State<Posts> createState() => _PostsState();
}

class _PostsState extends State<Posts> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Material(
        elevation: 5,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: Colors.grey, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    child: ClipOval(
                      child: Image.asset(
                        widget.profilePic,
                        fit: BoxFit.cover,
                        width: 40, // Ensures the image covers the CircleAvatar
                        height: 40,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 9,
                  ),
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
                                SizedBox(
                                  width: 6,
                                ),
                                Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 15,
                                )
                              ],
                            ),
                            // SizedBox(
                            //   height: 5,
                            // ),
                            // Text(
                            //   'Thomas',
                            //   style: TextStyle(
                            //       fontWeight: FontWeight.bold, fontSize: 12),
                            // )
                          ],
                        ),
                        Icon(Icons.more_vert)
                      ],
                    ),
                  )
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Image.asset(
                widget.image,
                width: double.infinity, // Takes full width
                height: MediaQuery.of(context).size.width *
                    0.50, // Set height dynamically
                fit: BoxFit
                    .contain, // Ensures the entire image is visible without cropping
              ),
              SizedBox(
                height: 12,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(FontAwesomeIcons.heart),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        widget.likeCount,
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Image.asset(
                        'assets/images/comment--removebg-preview.png',
                        width: 29,
                        height: 29,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        widget.commentCount,
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(
                        width: 8,
                      ),
                      Image.asset(
                        'assets/images/share--removebg-preview.png',
                        width: 29,
                        height: 29,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        widget.shareCount,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/bookmark-removebg-preview.png',
                        width: 29,
                        height: 29,
                      ),
                      SizedBox(
                        width: 5,
                      ),
                      Text(
                        widget.bookmarkCount,
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  )
                ],
              ),
              SizedBox(
                height: 8,
              ),
              Text('${widget.userName}  ${widget.caption}... more'),
              SizedBox(
                height: 5,
              ),
              Text(
                widget.postTime,
                style: TextStyle(color: Colors.grey[500]),
              )
            ],
          ),
        ),
      ),
    );
  }
}
