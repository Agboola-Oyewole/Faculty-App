import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';
import '../components/event_card.dart';
import 'event_detail_screen.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  String _formatDate(String? isoDate) {
    if (isoDate == null) return "No Date";
    DateTime date = DateTime.parse(isoDate);
    return "${date.day} ${_getMonthName(date.month)}";
  }

  String _getMonthName(int month) {
    List<String> months = [
      "",
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back button behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Exit the app
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => BottomNavBar()));
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(
            top: 30.0, left: 15.0, right: 15.0, bottom: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Upcoming Events',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance.collection('events').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                        child: CircularProgressIndicator()); // Show loading
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                        child: Text(
                            "No events available")); // Show message if empty
                  }

                  var events = snapshot.data!.docs;

                  return Expanded(
                    child: ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        var eventData =
                            events[index].data() as Map<String, dynamic>;

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailsScreen(
                                  eventId: eventData['eventId'],
                                  currentUserId:
                                      FirebaseAuth.instance.currentUser!.uid,
                                  imageUrl: eventData['image'] ??
                                      'assets/images/default_event.jpg',
                                  title: eventData['title'] ?? 'No Title',
                                  date: eventData['date_start'] != null
                                      ? _formatDate(eventData[
                                          'date_start']) // Convert timestamp to readable format
                                      : 'Unknown Date',
                                  location: eventData['location'] ??
                                      'Unknown Location',
                                  description: eventData['description'] ??
                                      'No Description Available',
                                  tags: eventData['tag'],
                                  tickets: [
                                    TicketOption(
                                      type: 'First Pre-Sale',
                                      price:
                                          eventData['presale_ticket_price'] ??
                                              '₦0',
                                      isSoldOut:
                                          false, // You can implement this dynamically later
                                    ),
                                    TicketOption(
                                      type: 'Regular Ticket',
                                      price: eventData['ticket_price'] ?? '₦0',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: EventCard(
                            imageUrl: eventData['image'] ??
                                'assets/images/default_event.jpg',
                            title: eventData['title'] ?? 'No Title',
                            priceRange: eventData['ticket_price'] == '0' ||
                                    eventData['ticket_price'] == ''
                                ? 'Free'
                                : '₦${eventData['ticket_price']}',
                            location:
                                eventData['location'] ?? 'Unknown Location',
                            date: eventData['date_start'] != null
                                ? _formatDate(eventData['date_start'])
                                : 'Unknown Date',
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
