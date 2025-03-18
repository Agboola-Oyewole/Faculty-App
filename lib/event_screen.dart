import 'package:flutter/material.dart';

import 'event_card.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
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
            height: 15,
          ),
          EventCard(
            imageUrl: 'assets/images/sumup-ru18KXzFA4E-unsplash.jpg',
            title: 'Bernadya Solo Concert',
            priceRange: '10k - 50k',
            location: 'Lagoon Front, Unilag',
            date: 'Aug 24',
          ),

        ],
      ),
    );
  }
}
