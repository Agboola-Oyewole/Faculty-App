import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/screens/attendance_screen.dart';
import 'package:faculty_app/screens/personal_details.dart';
import 'package:faculty_app/screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'bottom_nav_bar.dart';

// ✅ Global navigator key for notification taps
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background Message: ${message.notification?.body}");
  showNotification(
      message.notification?.title, message.notification?.body, message.data);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ✅ Initialize Notifications
  await initNotifications();
  setupFirebaseMessaging();

  // ✅ Background notification handling
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
                  backgroundColor: Colors.white,
                  body: Center(
                      child: CircularProgressIndicator(color: Colors.black)),
                );
              } else if (userSnapshot.hasData && userSnapshot.data != null) {
                bool hasMissingFields = [
                  'date_of_birth',
                  'department',
                  'level',
                  'faculty',
                  'gender'
                ].any((field) => (userSnapshot.data![field] == null ||
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

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (details) {
      final payload = details.payload;
      final type = jsonDecode(payload!)['type'];

      if (type == 'attendance') {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => AttendanceScreen(),
        ));
      } else {
        navigatorKey.currentState?.push(MaterialPageRoute(
          builder: (_) => BottomNavBar(),
        ));
      }
    },
  );

  // If app is opened from terminated state by tapping notification
  RemoteMessage? initialMessage =
      await FirebaseMessaging.instance.getInitialMessage();

  if (initialMessage != null) {
    // Retrieve the type from the payload
    final type = initialMessage.data['type'];

    if (type == 'attendance') {
      // Navigate to AttendanceScreen if type is 'attendance'
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => AttendanceScreen(), // 👉 Navigate to AttendanceScreen
      ));
    } else {
      // Navigate to BottomNavBar for other types
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => BottomNavBar(), // 👉 Navigate to BottomNavBar
      ));
    }
  }
}

// ✅ Setup Firebase Messaging
void setupFirebaseMessaging() {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  messaging.requestPermission(alert: true, badge: true, sound: true);

  // Foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground Notification: ${message.notification?.body}");
    showNotification(
        message.notification?.title, message.notification?.body, message.data);
  });

  // Tap on notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final type = message.data['type'];

    if (type == 'attendance') {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => AttendanceScreen(),
      ));
    } else {
      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => BottomNavBar(),
      ));
    }
  });

  // FCM token refresh
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({"fcmToken": newToken});
      print("🔄 FCM Token Refreshed and Updated: $newToken");
    }
  });
}

// ✅ Show notification
void showNotification(String? title, String? body, Map<String, dynamic> data) {
  var androidDetails = AndroidNotificationDetails(
    'channelId',
    'channelName',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
  );

  var notificationDetails = NotificationDetails(android: androidDetails);

  flutterLocalNotificationsPlugin.show(0, title, body, notificationDetails,
      payload: jsonEncode(data));
}
