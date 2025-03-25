import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../bottom_nav_bar.dart';

class EventDetailsScreen extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String date;
  final String location;
  final String description;
  final String currentUserId;
  final String eventId;
  final String eventPosterId;
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
    required this.eventPosterId,
    required this.currentUserId,
    required this.tickets,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool isLoading = false;
  bool isLoadingDelete = false;
  Map<String, int> ticketCounts = {}; // Keeps track of ticket quantities
  int count = 0;

  @override
  void initState() {
    super.initState();
    // Initialize counts for each ticket type to 0
    for (var ticket in widget.tickets) {
      ticketCounts[ticket.type] = 0;
    }
    print('THIS IS TICKECT COUNT: $ticketCounts');
  }

  void resetParameters() {
    for (var ticket in widget.tickets) {
      ticketCounts[ticket.type] = 0;
    }
  }

  Future<void> addEventAttendees() async {
    setState(() => isLoading = true);
    try {
      // Convert ticketCounts map to a list of selected tickets
      List<Map<String, dynamic>> selectedTickets = [];
      ticketCounts.forEach((type, count) {
        if (count > 0) {
          selectedTickets.add({"type": type, "quantity": count});
        }
      });

      if (selectedTickets.isEmpty) {
        print("⚠️ No tickets selected.");
        setState(() => isLoading = false);
        return;
      }

      // Check if user is already an attendee
      QuerySnapshot existingAttendee = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('attendees')
          .where("userId", isEqualTo: widget.currentUserId)
          .get();

      if (existingAttendee.docs.isNotEmpty) {
        print("⚠️ User already registered.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('You are already registered for this event!')),
        );
        setState(() => isLoading = false);
        return;
      }

      // Add new attendee if not already registered
      await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .collection('attendees')
          .add({
        "userId": widget.currentUserId,
        "tickets": selectedTickets,
        "timestamp": FieldValue.serverTimestamp(),
      });

      print("✅ Attendee added successfully.");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully registered for event!')),
      );
      resetParameters();
    } catch (e) {
      print("❌ Error adding attendee: $e");
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Event?"),
        content: const Text("Are you sure you want to delete this event?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteEvent();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> deleteEvent() async {
    setState(() => isLoadingDelete = true);
    try {
      DocumentReference eventRef =
          FirebaseFirestore.instance.collection('events').doc(widget.eventId);
      DocumentSnapshot eventSnapshot = await eventRef.get();

      if (!eventSnapshot.exists) return;

      String? imageUrl = eventSnapshot['image'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          String filePath =
              Uri.decodeFull(imageUrl.split('o/')[1].split('?')[0]);
          await FirebaseStorage.instance.ref(filePath).delete();
        } catch (e) {
          print("Error deleting image: $e");
        }
      }
      // Delete all comments associated with the post first
      var attendeesSnapshot = await eventRef.collection('attendees').get();
      for (var doc in attendeesSnapshot.docs) {
        await doc.reference.delete();
      }

      await eventRef.delete();
    } catch (e) {
      print("Error deleting event: $e");
    } finally {
      if (mounted) {
        setState(() => isLoadingDelete = true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => BottomNavBar(initialIndex: 1)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoadingDelete
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform.scale(
                    scale: 0.8,
                    // Reduce the size by scaling down (0.8 means 80% of the original size)
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      strokeWidth: 4,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    'Deleting Event...',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 20),
                  )
                ],
              ),
            )
          : Stack(
              children: [
                ListView(
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(20)),
                          child: widget.imageUrl != null &&
                                  widget.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.imageUrl,
                                  width: double.infinity,
                                  height: 250,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/sumup-ru18KXzFA4E-unsplash.jpg',
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
                              icon: const Icon(Icons.arrow_back,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                        if (widget.currentUserId == widget.eventPosterId)
                          Positioned(
                            top: 30,
                            right: 15,
                            child: CircleAvatar(
                              backgroundColor: Colors.black.withOpacity(0.5),
                              child: IconButton(
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white),
                                onPressed: confirmDelete,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: widget.tags
                                .map((tag) => Chip(
                                    label: Text(tag),
                                    backgroundColor: const Color(0xffC7FFD8)))
                                .toList(),
                          ),
                          const SizedBox(height: 8),
                          Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Text(widget.date,
                                  style: const TextStyle(color: Colors.grey)),
                              const SizedBox(width: 20),
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(widget.location,
                                    style: const TextStyle(color: Colors.grey)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text("About Event",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(widget.description,
                              style: const TextStyle(color: Colors.black54)),
                          const SizedBox(height: 20),
                          const Text("Available Tickets",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          Column(children: [
                            TicketItem(
                              ticket: widget.tickets[0],
                              count: ticketCounts[widget.tickets[0].type]!,
                              onCountChanged: (newCount) {
                                setState(() {
                                  ticketCounts[widget.tickets[0].type] =
                                      newCount;
                                });
                              },
                            )
                          ]),
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
                      backgroundColor: const Color(0xff347928),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onPressed: addEventAttendees,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Buy Tickets",
                            style:
                                TextStyle(fontSize: 18, color: Colors.white)),
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
  int quantity;

  TicketOption({
    required this.type,
    required this.price,
    this.isSoldOut = false,
    this.quantity = 0,
  });
}

class TicketItem extends StatefulWidget {
  final TicketOption ticket;
  final int count;
  final Function(int) onCountChanged;

  const TicketItem({
    super.key,
    required this.ticket,
    required this.count,
    required this.onCountChanged,
  });

  @override
  State<TicketItem> createState() => _TicketItemState();
}

class _TicketItemState extends State<TicketItem> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.ticket.type,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text('₦${widget.ticket.price}',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
          widget.ticket.isSoldOut
              ? const Text("Sold Out", style: TextStyle(color: Colors.red))
              : widget.ticket.price == '0'
                  ? Text("Free", style: TextStyle(color: Colors.green))
                  : Row(
                      children: [
                        IconButton(
                          onPressed: widget.count > 0
                              ? () => widget.onCountChanged(widget.count - 1)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text("${widget.count}"),
                        IconButton(
                          onPressed: () =>
                              widget.onCountChanged(widget.count + 1),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }
}
