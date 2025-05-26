import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/lecturer/personal_details.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../bottom_nav_bar.dart';

class OnboardingPage1Lecturer extends StatefulWidget {
  const OnboardingPage1Lecturer({super.key});

  @override
  State<OnboardingPage1Lecturer> createState() =>
      _OnboardingPage1LecturerState();
}

class _OnboardingPage1LecturerState extends State<OnboardingPage1Lecturer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: OnboardingPagePresenter(pages: [
        OnboardingPageModel(
          title: 'Connect With Your Students',
          description: 'Send updates, assignments, and resources in real-time.',
          imageUrl: 'assets/images/Teaching-amico.png',
          bgColor: Colors.black,
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
  bool isLecturerLogin = false; // Track loading state

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
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => PersonalInfoScreenLecturer()));
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
      // Determine role
      final role = isLecturerLogin ? 'lecturer' : 'student';

      // Common data
      Map<String, dynamic> data = {
        'first_name': user.displayName?.split(" ").first ?? "",
        'last_name': user.displayName?.split(" ").last ?? "",
        'profile_pic': user.photoURL ?? "",
        'email': user.email,
        'faculty': "",
        'gender': "",
        'created_at': FieldValue.serverTimestamp(),
        'role': role,
      };

      // Add lecturer-specific fields
      if (role == 'lecturer') {
        data.addAll({
          'departments': [],
          'courses': [],
        });
      }

      await userRef.set(data);
      print("✅ ${role.toUpperCase()} created in Firestore.");

      // 🔐 Get and save FCM token
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
      }

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
                            : Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0),
                                child: Text(
                                  'Welcome to FES Connect Lecturer Page!',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                      color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                        SizedBox(
                          height: 50,
                        ),
                        Column(children: [
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
                            constraints: const BoxConstraints(maxWidth: 280),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 8.0),
                            child: Text(item.description,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: item.textColor, fontSize: 15)),
                          )
                        ])
                      ],
                    );
                  },
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40, top: 80),
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
                        onPressed: isLoading
                            ? null
                            : () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    final TextEditingController codeController =
                                        TextEditingController();

                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      backgroundColor: Colors.grey[900],
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.white30, width: 1),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Lecturer Access',
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            TextField(
                                              controller: codeController,
                                              obscureText: true,
                                              style: TextStyle(
                                                  color: Colors.white),
                                              decoration: InputDecoration(
                                                hintText: 'Enter access code',
                                                hintStyle: TextStyle(
                                                    color: Colors.white54),
                                                filled: true,
                                                fillColor: Colors.grey[800],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                      color: Colors.white24),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  borderSide: BorderSide(
                                                      color: Colors.white54,
                                                      width: 2),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 20),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(
                                                        color: Colors.white70),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.black,
                                                    // minimumSize: const Size(double.infinity, 50),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8),
                                                    ),
                                                  ),
                                                  onPressed: () async {
                                                    print(codeController.text);
                                                    final enteredCode =
                                                        codeController.text
                                                            .trim();
                                                    if (enteredCode ==
                                                        'Lect@UNILAG25*') {
                                                      Navigator.pop(context);

                                                      isLecturerLogin = true;

                                                      await signInWithGoogle();

                                                      isLecturerLogin = false;
                                                    } else {
                                                      Navigator.pop(context);
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            "❌ Invalid Access Code.",
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .black),
                                                          ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                          backgroundColor:
                                                              Colors.white,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            side: BorderSide(
                                                                color: Colors
                                                                    .black),
                                                          ),
                                                          margin:
                                                              EdgeInsets.all(
                                                                  16),
                                                          elevation: 3,
                                                          duration: Duration(
                                                              seconds: 3),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    'Continue',
                                                    style: TextStyle(
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
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
                                      color: Colors.black, // Customize color
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
