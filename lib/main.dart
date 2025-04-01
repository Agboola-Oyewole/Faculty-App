import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/screens/personal_details.dart';
import 'package:faculty_app/screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bottom_nav_bar.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Background Message: ${message.notification?.body}");
  showNotification(message.notification?.title, message.notification?.body);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Initialize Notifications
  await initNotifications();
  setupFirebaseMessaging();

  // ✅ Handle background notifications
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Poppins'),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  Future<Map<String, dynamic>?> fetchUserDetails(String uid) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> doc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        return doc.data();
      } else {
        print("❌ User document not found in Firestore.");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching user details: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: fetchUserDetails(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  body: Center(
                      child:
                      CircularProgressIndicator(color: Color(0xff347928))),
                );
              } else if (userSnapshot.hasData && userSnapshot.data != null) {
                bool hasMissingFields = [
                  'date_of_birth',
                  'department',
                  'level',
                  'faculty',
                  'gender'
                ].any((field) =>
                (userSnapshot.data![field] == null ||
                    (userSnapshot.data![field] as String).isEmpty));

                if (hasMissingFields) {
                  print('⚠️ Redirecting to Personal Info (incomplete details)');
                  return PersonalInfoScreen();
                } else {
                  print('✅ Redirecting to BottomNavBar (complete details)');
                  return BottomNavBar();
                }
              } else {
                print(
                    "❌ Error retrieving user data, defaulting to Personal Info.");
                return PersonalInfoScreen();
              }
            },
          );
        } else {
          return OnboardingPage1();
        }
      },
    );
  }
}

// ✅ Initialize Local Notifications
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

// ✅ Setup Firebase Messaging for handling notifications
void setupFirebaseMessaging() {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permission for notifications
  messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Listen for new messages while the app is in foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground Notification: ${message.notification?.body}");
    showNotification(message.notification?.title, message.notification?.body);
  });

  // Handle when a user taps on a notification and opens the app
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📂 Notification Clicked!");
  });

  // ✅ Listen for token refresh and update Firestore
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "fcmToken": newToken,
      });
      print("🔄 FCM Token Refreshed and Updated: $newToken");
    }
  });
}

// ✅ Show notification in the system tray
void showNotification(String? title, String? body) {
  var androidDetails = AndroidNotificationDetails(
    'channelId',
    'channelName',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  var notificationDetails = NotificationDetails(android: androidDetails);
  flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails);
}
