import 'package:faculty_app/bottom_nav_bar.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const BottomNavBar(),
      theme: ThemeData(
        fontFamily: 'Railway', // Set your custom font family here
      ),
    ),
  );
}
