import 'package:faculty_app/post_card.dart';
import 'package:flutter/material.dart';

import 'content_create_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          top: 30.0, left: 15.0, right: 15.0, bottom: 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer(); // Opens sidebar
                    },
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.white60,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0)),
                          border: Border.all(color: Colors.black, width: 1)),
                      padding: const EdgeInsets.all(10.0),
                      child: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Text(
                    'EcoCampus',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ],
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.black,
                            size: 30,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 10,
                                minHeight: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          SizedBox(
            height: 15,
          ),
          Container(
            color: Colors.grey.withOpacity(0.5),
            height: 1.0,
          ),
          SizedBox(
            height: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CreateContentScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff347928),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_box_outlined,
                      color: Colors.white,
                    ),
                    SizedBox(
                      width: 4,
                    ),
                    Text(
                      "New post",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: 5,
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: [
                  Posts(
                      userName: 'Thomas',
                      profilePic: 'assets/images/agboola.jpg',
                      caption:
                          'GOAT...You all know...cant deny this man, was and alwasy will be',
                      commentCount: '37k',
                      image: 'assets/images/post_image.jpg',
                      likeCount: '43m',
                      postTime: '12 hours ago',
                      bookmarkCount: '2',
                      isVerified: true,
                      shareCount: '73'),
                  Posts(
                      userName: 'Thomas',
                      profilePic: 'assets/images/agboola.jpg',
                      caption:
                          'GOAT...You all know...cant deny this man, was and alwasy will be',
                      commentCount: '37k',
                      image: 'assets/images/agboola.jpg',
                      likeCount: '43m',
                      postTime: '8 hours ago',
                      isVerified: true,
                      bookmarkCount: '44',
                      shareCount: '73'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
