import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          title: const Text("Notifications"),
          backgroundColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotificationSettingsScreen()));
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNotificationSection("New", [
                _notificationItem("levileon", "started following you.", "34m"),
                _notificationItem("halukman", "started following you.", "2h"),
                _notificationItem("mbestra", "liked your reel.", "6h"),
              ]),
              _buildNotificationSection("Yesterday", [
                _notificationItem("verna.dare", "liked your story.", "13h"),
                _notificationItem("alvian.design", "liked your story.", "14h"),
                _notificationItem("kretyastudio", "liked your story.", "14h"),
                _notificationItem(
                    "fateme_ahmadi", "started following you.", "16h"),
              ]),
              _buildNotificationSection("Last 7 days", [
                _notificationItem("zahrakan", "liked your post.", "2d"),
                _notificationItem("cristop.rowing", "liked your post.", "2d"),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Column(children: items),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _notificationItem(String username, String action, String time) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.grey,
      ),
      title: Text(
        "$username $action",
        style: const TextStyle(fontSize: 16),
      ),
      subtitle: Text(time),
      trailing: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: const Text("Follow"),
      ),
    );
  }
}

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pauseNotifications = false;

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
          title: const Text("Notification Settings"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_off),
                title: const Text("Pause all"),
                subtitle: const Text("Temporarily pause notifications"),
                trailing: Switch(
                  value: _pauseNotifications,
                  onChanged: (value) {
                    setState(() {
                      _pauseNotifications = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
