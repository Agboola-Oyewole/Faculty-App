import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:faculty_app/bottom_nav_bar.dart';
import 'package:faculty_app/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'excos_page.dart';
import 'notification_screen.dart';

// Profile Screen
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> signOut() async {
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    }

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
          children: [
            _buildHeader(),
            SizedBox(
              height: 30,
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildSectionTitle("Account Settings"),
                  _buildMenuItem(
                    context,
                    title: "Personal Information",
                    icon: Icons.person,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PersonalInfoScreen()),
                    ),
                  ),
                  // _buildMenuItem(
                  //   context,
                  //   title: "Password & Security",
                  //   icon: Icons.lock,
                  //   onTap: () => Navigator.push(
                  //     context,
                  //     MaterialPageRoute(builder: (_) => SecurityScreen()),
                  //   ),
                  // ),
                  _buildMenuItem(
                    context,
                    title: "Notifications Preferences",
                    icon: Icons.notifications,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  NotificationSettingsScreen()));
                    },
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  _buildSectionTitle("Community Settings"),
                  _buildMenuItem(
                    context,
                    title: "Meet the Excos",
                    icon: Icons.people,
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => ExcosPage()));
                    },
                  ),
                  // _buildMenuItem(
                  //   context,
                  //   title: "Friends & Social",
                  //   icon: Icons.people,
                  //   onTap: () {},
                  // ),
                  // _buildMenuItem(
                  //   context,
                  //   title: "Following List",
                  //   icon: Icons.list,
                  //   onTap: () {},
                  // ),
                  SizedBox(
                    height: 10,
                  ),
                  _buildSectionTitle("Other"),
                  _buildMenuItem(
                    context,
                    title: "FAQ",
                    icon: Icons.help,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    title: "Help Center",
                    icon: Icons.support_agent,
                    onTap: () {},
                  ),
                  _buildMenuItem(
                    context,
                    title: "Logout",
                    icon: Icons.logout,
                    onTap: () {
                      signOut();
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => OnboardingPage1()));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String? userDisplayName = FirebaseAuth.instance.currentUser?.displayName;
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage: AssetImage('assets/images/agboola.jpg'),
        ),
        SizedBox(height: 10),
        Text(
          userDisplayName!,
          style: TextStyle(
              color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          userEmail!,
          style: TextStyle(color: Colors.black45),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required String title,
      required IconData icon,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

// Personal Information Screen
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  Future<Map<String, dynamic>?> fetchCurrentUserDetails() async {
    try {
      // Get the currently signed-in user
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("❌ No user is currently signed in.");
        return null;
      }

      // Reference to Firestore document
      DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        print("❌ User document not found in Firestore.");
        return null;
      }

      // Return user details as a Map
      return doc.data();
    } catch (e) {
      print("❌ Error fetching user details: $e");
      return null;
    }
  }

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
          title: Text("Personal Information"),
        ),
        body: Padding(
          padding: EdgeInsets.all(16.0),
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text("User data not found."));
              }

              var userData = snapshot.data!.data() as Map<String, dynamic>;

              return Column(
                children: [
                  // Profile Picture & Edit Button
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 50,
                          backgroundImage: userData['profile_pic'] != null &&
                                  userData['profile_pic'].isNotEmpty
                              ? NetworkImage(userData['profile_pic'])
                              : AssetImage('assets/images/user.png')
                                  as ImageProvider,
                        ),
                        SizedBox(height: 15),
                        // Container(
                        //   decoration: BoxDecoration(
                        //     color: Colors.white60,
                        //     borderRadius:
                        //         BorderRadius.all(Radius.circular(10.0)),
                        //     border: Border.all(color: Colors.black, width: 1),
                        //   ),
                        //   padding: EdgeInsets.all(7.0),
                        //   child: GestureDetector(
                        //     onTap: () {},
                        //     child: Text(
                        //       "Edit Profile",
                        //       style: TextStyle(
                        //           color: Colors.black,
                        //           fontWeight: FontWeight.w900),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),

                  // Scrollable Fields
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildTextField("First Name",
                              userData['first_name'] ?? "Not provided"),
                          _buildTextField("Last Name",
                              userData['last_name'] ?? "Not provided"),
                          _buildTextField("Date of Birth",
                              userData['date_of_birth'] ?? "Not provided"),
                          _buildTextField("Department",
                              userData['department'] ?? "Not provided"),
                          _buildTextField(
                              "Faculty", userData['faculty'] ?? "Not provided"),
                          _buildDropdownField(
                              "Gender", userData['gender'] ?? "Not specified"),
                        ],
                      ),
                    ),
                  ),

                  // Save Button (Fixed at Bottom)
                  SizedBox(height: 10),
                  // ElevatedButton(
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: Color(0xffC7FFD8),
                  //     elevation: 3,
                  //     shape: RoundedRectangleBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //     minimumSize:
                  //         Size(double.infinity, 50), // Full-width button
                  //   ),
                  //   onPressed: () {
                  //     // Implement save function
                  //   },
                  //   child: Text(
                  //     "Save",
                  //     style: TextStyle(
                  //         color: Colors.black, fontWeight: FontWeight.w900),
                  //   ),
                  // ),
                  // SizedBox(height: 15),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey.shade200,
        ),
        controller: TextEditingController(text: value),
        enabled: false,
      ),
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: Color(0xff347928),
              width: 1.5,
            ),
          ),
        ),
        isExpanded: false,
        items: ["Male", "Female"].map((gender) {
          return DropdownMenuItem(value: gender, child: Text(gender));
        }).toList(),
        onChanged: (value) {},
      ),
    );
  }
}

// // Password & Security Screen
// class SecurityScreen extends StatelessWidget {
//   const SecurityScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Password & Security"),
//         backgroundColor: Colors.indigo.shade900,
//       ),
//       body: ListView(
//         padding: EdgeInsets.all(16.0),
//         children: [
//           _buildSecurityItem("Change Password", Icons.lock, "PIN"),
//           _buildSecurityItem("Face ID", Icons.face, "Not Registered"),
//           _buildSecurityItem(
//               "Verified Phone Number", Icons.phone, "Not Registered"),
//           _buildSecurityItem(
//               "Verified Email Address", Icons.email, "Registered",
//               isRegistered: true),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSecurityItem(String title, IconData icon, String status,
//       {bool isRegistered = false}) {
//     return ListTile(
//       leading: Icon(icon, color: Colors.black54),
//       title: Text(title),
//       trailing: Text(
//         status,
//         style: TextStyle(
//           color: isRegistered ? Colors.green : Colors.red,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       onTap: () {},
//     );
//   }
// }
