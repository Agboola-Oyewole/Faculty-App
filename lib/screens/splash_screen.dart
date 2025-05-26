import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/lecturer/splash_screen.dart';
import 'package:faculty_app/screens/personal_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../bottom_nav_bar.dart';

class OnboardingPage1 extends StatefulWidget {
  const OnboardingPage1({super.key});

  @override
  State<OnboardingPage1> createState() => _OnboardingPage1State();
}

class _OnboardingPage1State extends State<OnboardingPage1> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingPagePresenter(pages: [
        OnboardingPageModel(
          title: 'Stay Informed, Stay Ahead',
          description: 'Get real-time updates on lectures.',
          imageUrl: 'assets/images/Learning-rafiki.png',
          bgColor: Colors.black, // Deep Green
        ),
        OnboardingPageModel(
          title: 'Find Lecturers & Offices Easily',
          description: 'A simple directory to search for lecturers.',
          imageUrl: 'assets/images/Teaching-amico.png',
          bgColor: Colors.black, // Soft Off-White
        ),
        OnboardingPageModel(
          title: 'Never Miss a Class',
          description: 'Access lecture timetables and exam schedules easily.',
          imageUrl: 'assets/images/Learning-cuate.png',
          bgColor: Colors.black, // Navy Blue
        ),
      ]),
    );
  }
}

class OnboardingPagePresenter extends StatefulWidget {
  final List<OnboardingPageModel> pages;
  final VoidCallback? onSkip;
  final VoidCallback? onFinish;

  const OnboardingPagePresenter(
      {super.key, required this.pages, this.onSkip, this.onFinish});

  @override
  State<OnboardingPagePresenter> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPagePresenter> {
  // Store the currently visible page
  int _currentPage = 0;
  bool isLoading = false; // Track loading state

  // Define a controller for the pageview
  final PageController _pageController = PageController(initialPage: 0);

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print("Google sign-in was canceled.");
        return; // User canceled the sign-in process
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      // Get user info
      final User? user = userCredential.user;

      if (user != null) {
        print("✅ User Signed In: ${user.displayName}");
        print("📧 Email: ${user.email}");
        print("📷 Profile Pic: ${user.photoURL}");

        bool isNewUser = await checkAndCreateUser(user);

        // Redirect based on user status
        if (mounted) {
          if (isNewUser) {
            print('Inside the personal');
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => PersonalInfoScreen()));
          } else {
            print('Inside the bottom');
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => BottomNavBar()));
          }
        }
      }
    } catch (e) {
      print("❌ Error during Google Sign-In: $e");
    } finally {
      // Stop loading after the process completes
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<bool> checkAndCreateUser(User user) async {
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      // Create new user
      await userRef.set({
        'first_name': user.displayName?.split(" ").first ?? "",
        'last_name': user.displayName?.split(" ").last ?? "",
        'profile_pic': user.photoURL ?? "",
        'email': user.email,
        'department': "",
        'level': "",
        'faculty': "",
        'gender': "",
        'matricNo': "",
        'username': "",
        'role': "student",
        'created_at': FieldValue.serverTimestamp(),
      });

      // Create schedule
      final docRef =
          FirebaseFirestore.instance.collection('schedules').doc(user.uid);
      final scheduleDoc = await docRef.get();
      if (!scheduleDoc.exists) {
        await docRef.set({
          "userId": user.uid,
          "schedule": {
            "Monday": [],
            "Tuesday": [],
            "Wednesday": [],
            "Thursday": [],
            "Friday": [],
            "Saturday": [],
            "Sunday": []
          }
        });
      }
      print("✅ User Schedule Data Created: ${user.displayName}");

      // 🔐 Request permission and fetch token
      await FirebaseMessaging.instance.requestPermission();

      String? token;

      if (kIsWeb) {
        token = await FirebaseMessaging.instance.getToken(
          vapidKey:
              'BA4nxj2rLUAyqLe9CdvClHfpVVfWLWoH1mCpNtZyIVREFrm_FHlDbV1Bke5PZixujthOIvhG7XYInHAwalmaWzA',
        );
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }

      if (token != null) {
        await userRef.set({"fcmToken": token}, SetOptions(merge: true));
        print("✅ FCM Token saved: $token");
      } else {
        print("❌ Failed to get FCM token.");
      }

      print("✅ New user created in Firestore.");
      return true;
    } else {
      print("ℹ️ User already exists in Firestore.");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              widget.pages[_currentPage].bgColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Pageview to render each page
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: widget.pages.length,
                  onPageChanged: (idx) {
                    // Change current page when pageview changes
                    setState(() {
                      _currentPage = idx;
                    });
                  },
                  itemBuilder: (context, idx) {
                    final item = widget.pages[idx];
                    return Column(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Image.asset(
                              item.imageUrl,
                            ),
                          ),
                        ),
                        _currentPage != 0
                            ? Container()
                            : Text(
                                'Welcome to FES Connect!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: Colors.white),
                              ),
                        SizedBox(
                          height: 50,
                        ),
                        Expanded(
                            flex: 1,
                            child: Column(children: [
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text(item.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: item.textColor,
                                            fontSize: 18)),
                              ),
                              Container(
                                constraints:
                                    const BoxConstraints(maxWidth: 280),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0, vertical: 8.0),
                                child: Text(item.description,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                            color: item.textColor,
                                            fontSize: 15)),
                              )
                            ]))
                      ],
                    );
                  },
                ),
              ),

              // Current page indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.pages
                    .map((item) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: _currentPage == widget.pages.indexOf(item)
                              ? 30
                              : 8,
                          height: 8,
                          margin: const EdgeInsets.all(2.0),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0)),
                        ))
                    .toList(),
              ),

              // Bottom buttons
              _currentPage != widget.pages.length - 1
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: SizedBox(
                        height: 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                                style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.comfortable,
                                    foregroundColor:
                                        _currentPage == widget.pages.length - 1
                                            ? Colors.black
                                            : Colors.white,
                                    textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                onPressed: () {
                                  if (_currentPage == widget.pages.length - 1) {
                                    widget.onSkip?.call();
                                  } else {
                                    _pageController.animateToPage(3,
                                        curve: Curves.easeInOutCubic,
                                        duration:
                                            const Duration(milliseconds: 250));
                                  }
                                },
                                child: const Text(
                                  "Skip",
                                  style: TextStyle(color: Colors.white),
                                )),
                            TextButton(
                              style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.comfortable,
                                  foregroundColor:
                                      _currentPage == widget.pages.length - 1
                                          ? Colors.black
                                          : Colors.white,
                                  textStyle: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (_currentPage == widget.pages.length - 1) {
                                  widget.onFinish?.call();
                                } else {
                                  _pageController.animateToPage(
                                      _currentPage + 1,
                                      curve: Curves.easeInOutCubic,
                                      duration:
                                          const Duration(milliseconds: 250));
                                }
                              },
                              child: Row(
                                children: [
                                  Text(
                                    _currentPage == widget.pages.length - 1
                                        ? "Finish"
                                        : "Next",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _currentPage == widget.pages.length - 1
                                        ? Icons.done
                                        : Icons.arrow_forward,
                                    color:
                                        _currentPage == widget.pages.length - 1
                                            ? Colors.black
                                            : Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10, top: 60),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            // Adjust the radius as needed
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 20),
                              ),
                              onPressed: isLoading ? null : signInWithGoogle,
                              // Disable button when loading
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    "assets/images/search.png",
                                    // Use a Google logo asset
                                    height: 24,
                                  ),
                                  isLoading
                                      ? const SizedBox(
                                          width: 50,
                                        )
                                      : const SizedBox(width: 15),
                                  isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color:
                                                Colors.black, // Customize color
                                            strokeWidth: 4,
                                          ),
                                        )
                                      : const Text(
                                          "Sign in with Google",
                                          style: TextStyle(color: Colors.black),
                                        ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        OnboardingPage1Lecturer()));
                          },
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: 30.0, top: 25),
                            child: Text(
                              'Not a student?',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageModel {
  final String title;
  final String description;
  final String imageUrl;
  final Color bgColor;
  final Color textColor;

  OnboardingPageModel(
      {required this.title,
      required this.description,
      required this.imageUrl,
      this.bgColor = Colors.blue,
      this.textColor = Colors.white});
}
