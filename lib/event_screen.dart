import 'package:flutter/material.dart';

import 'event_card.dart';
import 'event_detail_screen.dart';

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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsScreen(
                    imageUrl: 'assets/images/post_image.jpg',
                    title: 'Bernadya Solo Concert',
                    date: '24 August 2024',
                    location: 'Lagoon Front, Unilag',
                    description:
                        'Bernadya Solo Concert is an electrifying local pop-punk festival...',
                    tickets: [
                      TicketOption(
                          type: 'First Pre-Sale',
                          price: '₦10,000',
                          isSoldOut: true),
                      TicketOption(type: 'Second Pre-Sale', price: '₦20,000'),
                    ],
                  ),
                ),
              );
            },
            child: EventCard(
              imageUrl: 'assets/images/post_image.jpg',
              title: 'Bernadya Solo Concert',
              priceRange: 'Free',
              location: 'Lagoon Front, Unilag',
              date: 'Aug 24',
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsScreen(
                    imageUrl: 'assets/images/post_image.jpg',
                    title: 'Mosho Festival 2025',
                    date: '6 September 2025',
                    location: 'Lagoon Front, Unilag',
                    description:
                        'Mosho Festival 2025 is an electrifying local pop-punk festival...',
                    tickets: [
                      TicketOption(
                          type: 'First Pre-Sale',
                          price: '₦45,000',
                          isSoldOut: false),
                      TicketOption(type: 'Second Pre-Sale', price: '₦50,000'),
                    ],
                  ),
                ),
              );
            },
            child: EventCard(
              imageUrl: 'assets/images/sumup-ru18KXzFA4E-unsplash.jpg',
              title: 'Mosho Festival 2025',
              priceRange: '₦50,000',
              location: 'Afe-Babalola Hall, Unilag',
              date: 'Sep 6',
            ),
          ),
        ],
      ),
    );
  }
}
