import 'package:faculty_app/splash_screen.dart';
import 'package:flutter/material.dart';

void main() {
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
