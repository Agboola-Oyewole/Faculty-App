import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/content_create_screen.dart';

class ExamAndLectureCard extends StatelessWidget {
  final String title;
  final String firebaseCollection;

  const ExamAndLectureCard(
      {super.key, required this.title, required this.firebaseCollection});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity, // Full screen height
      width: double.infinity, // Full screen width
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            // Strong green at the top
            Color(0xffC7FFD8), // Soft green transition
            Colors.white,
            Colors.white, // Full white at the bottom
          ],
          stops: [
            0.0,
            0.7,
            1.0
          ], // Smooth transition: 20% green, then fade to white
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(title),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users') // Your users collection
              .doc(FirebaseAuth.instance.currentUser!.uid) // Current user
              .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                  child: CircularProgressIndicator(
                color: Colors.black,
              ));
            }

            // Get current user's department, level, and semester
            var userData = userSnapshot.data!;
            String department = userData['department'];
            String level = userData['level'];
            print(department);
            print(level);
            print('HOEUO');

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(firebaseCollection) // Your schedules collection
                  .where('department', isEqualTo: department)
                  .where('level', isEqualTo: level)
                  .snapshots(),
              builder: (context, scheduleSnapshot) {
                if (scheduleSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!scheduleSnapshot.hasData ||
                    scheduleSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No schedules available."));
                }

                var schedules = scheduleSnapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: schedules.length,
                  itemBuilder: (context, index) {
                    var schedule = schedules[index];
                    return _buildScheduleCard(schedule);
                  },
                );
              },
            );
          },
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.all(10.0),
          child: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CreateContentScreen(
                            tabIndex: title == 'Current Exam Schedule'
                                ? 3
                                : title == 'Lecture Timetable'
                                    ? 4
                                    : 0,
                          )));
            },
            backgroundColor: const Color(0xff347928),
            elevation: 5.0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: const Icon(
                Icons.add_a_photo,
                color: Colors.white,
                size: 25.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(QueryDocumentSnapshot schedule) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              schedule['image'], // Firestore image URL
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 10),
          Text(
            schedule['title'], // Lecture title
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.class_, color: Colors.grey, size: 16),
              SizedBox(width: 4),
              Text(
                "${schedule['department']}  |  ${schedule['semester']}",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${schedule['level']}",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Icon(Icons.download, color: Colors.black, size: 22),
            ],
          ),
        ],
      ),
    );
  }
}
