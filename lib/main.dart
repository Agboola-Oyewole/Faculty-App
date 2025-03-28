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
      theme: ThemeData(fontFamily: 'Railway'),
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
                child: CircularProgressIndicator(
              color: Colors.white,
            )),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return BottomNavBar();
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

  messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground Notification: ${message.notification?.body}");
    showNotification(message.notification?.title, message.notification?.body);
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📂 Notification Clicked!");
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
