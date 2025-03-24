import 'package:faculty_app/screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Railway'),
      home: AuthCheck(), // ✅ Automatically decides the first screen
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
            )), // Show loading screen while checking
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return BottomNavBar(); // ✅ User is logged in → Go to BottomNavBar screen
        } else {
          return OnboardingPage1(); // ❌ No user logged in → Go to Onboarding screen
        }
      },
    );
  }
}
