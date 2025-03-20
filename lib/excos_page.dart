import 'package:flutter/material.dart';

class ExcosPage extends StatefulWidget {
  const ExcosPage({super.key});

  @override
  State<ExcosPage> createState() => _ExcosPageState();
}

class _ExcosPageState extends State<ExcosPage> {
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
          title: Text("Meet the Excos"),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20),
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.7,
            ),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              return ProfileCard(profile: profiles[index]);
            },
          ),
        ),
      ),
    );
  }
}

class Profile {
  final String name;
  final String image;
  final String role;

  Profile({required this.name, required this.image, required this.role});
}

List<Profile> profiles = [
  Profile(
      name: "Alex Bernardo",
      image: "assets/images/sumup-ru18KXzFA4E-unsplash.jpg",
      role: 'Faculty President'),
  Profile(
      name: "Anna Chekovarian",
      image: "assets/images/post_image.jpg",
      role: 'Faculty Vice President'),
  Profile(
      name: "Vigdis Ravenskjold",
      image: "assets/images/post_image.jpg",
      role: 'Financial Secretary'),
  Profile(
      name: "Unknown",
      image: "assets/images/sumup-ru18KXzFA4E-unsplash.jpg",
      role: 'Sports Secretary'),
];

class ProfileCard extends StatelessWidget {
  final Profile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Image.asset(
            profile.image,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 15,
            right: 15, // Ensures the text doesn't overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150, // Adjust based on your layout
                  child: Text(
                    profile.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.visible, // Ensures wrapping
                    softWrap: true, // Allows text to wrap
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  width: 150,
                  child: Text(
                    profile.role,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
