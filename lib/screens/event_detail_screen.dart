import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EventDetailsScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String date;
  final String location;
  final String description;
  final String currentUserId;
  final String eventId;
  final List<TicketOption> tickets;
  final List<dynamic> tags;

  const EventDetailsScreen({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.date,
    required this.tags,
    required this.location,
    required this.description,
    required this.eventId,
    required this.currentUserId,
    required this.tickets,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isLoading = true;

  Future<void> addEventAttendees() async {
    setState(() {
      isLoading = true; // Start loading
    });
    try {
      DocumentReference eventsRef =
          FirebaseFirestore.instance.collection('events').doc(widget.eventId);

      await eventsRef.collection('attendees').add({
        "userId": widget.currentUserId,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("❌ Error during adding attendee: $e");
    } finally {
      // Stop loading after the process completes
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ListView(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                    child: Image.network(
                      widget.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 30,
                    left: 15,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withOpacity(0.5),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ),
                  widget.currentUserId == widget.eventId
                      ? Positioned(
                          top: 30,
                          right: 15,
                          child: CircleAvatar(
                            backgroundColor: Colors.black.withOpacity(0.5),
                            child: IconButton(
                              icon: Icon(Icons.more_vert, color: Colors.white),
                              onPressed: () {},
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8.0, // Space between chips
                      runSpacing: 4.0, // Space between rows if wrapped
                      children: widget.tags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          backgroundColor: Color(0xffC7FFD8),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.title,
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey),
                        SizedBox(width: 5),
                        Text(widget.date, style: TextStyle(color: Colors.grey)),
                        SizedBox(width: 10),
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 5),
                        Text(widget.location,
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "About Event",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(widget.description,
                        style: TextStyle(color: Colors.black54)),
                    SizedBox(height: 20),
                    Text(
                      "Available Tickets",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),
                    Column(
                      children: widget.tickets.map((ticket) {
                        return TicketItem(ticket: ticket);
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff347928),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: () {},
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Color(0xff347928), // Customize color
                        strokeWidth: 4,
                      ),
                    )
                  : Text("Buy Tickets",
                      style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class TicketOption {
  final String type;
  final String price;
  final bool isSoldOut;
  final int quantity;

  TicketOption({
    required this.type,
    required this.price,
    this.isSoldOut = false,
    this.quantity = 0,
  });
}

class TicketItem extends StatefulWidget {
  final TicketOption ticket;

  const TicketItem({super.key, required this.ticket});

  @override
  State<TicketItem> createState() => _TicketItemState();
}

class _TicketItemState extends State<TicketItem> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.ticket.type,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(widget.ticket.price, style: TextStyle(color: Colors.grey)),
            ],
          ),
          widget.ticket.isSoldOut
              ? Text("Sold Out", style: TextStyle(color: Colors.red))
              : Row(
                  children: [
                    IconButton(
                      onPressed: _count > 0
                          ? () {
                              setState(() {
                                _count--;
                              });
                            }
                          : null,
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                    Text("$_count"),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _count++;
                        });
                      },
                      icon: Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
