import 'package:faculty_app/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const OnboardingPage1(),
      theme: ThemeData(
        fontFamily: 'Railway', // Set your custom font family here
      ),
    ),
  );
}
