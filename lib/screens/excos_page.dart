import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ExcosPage extends StatefulWidget {
  const ExcosPage({super.key});

  @override
  State<ExcosPage> createState() => _ExcosPageState();
}

class _ExcosPageState extends State<ExcosPage> {
  File? _imagePost;
  bool isLoading = false;
  List<Map<String, dynamic>> profiles = [];
  bool isLoadingFetching = true; // To show a loading indicator
  final TextEditingController nameController = TextEditingController();
  String? selectedRole;
  String? selectedSession;
  String? _selectedDepartment;
  final List<String> departments = [
    "Architecture",
    "Building",
    "Estate Management",
    "Urban & Regional Planning",
    "Quantity Surveying",
  ];

  List<String> academicSessions = [
    "2024/2025",
    "2025/2026",
    "2026/2027",
    "2027/2028",
    "2028/2029",
    "2029/2030",
    "2030/2031",
    "2031/2032",
    "2032/2033",
    "2033/2034",
  ];

  final List<String> roles = [
    'Faculty President',
    "Faculty Vice President",
    'Sports Secretary',
    'Public Relations Officer',
    'Class Rep',
    'Assistant Class Rep'
  ];

  void _clearForm() {
    setState(() {
      nameController.clear();
      _imagePost = null;
      selectedRole = null;
      selectedSession = null;
    });
    print("✅ Form cleared successfully!");
  }

  @override
  void initState() {
    super.initState();
    fetchAllExcos();
  }

  Future<void> _pickImagePost(Function setModalState) async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setModalState(() {
        _imagePost = File(pickedFile.path);
      });
    }
  }

  void showAddRoleBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push content up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // 👈 Create local state inside modal
            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
              child: Wrap(
                children: [
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      margin: EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 25.0, top: 5),
                    child: Center(
                        child: Text(
                      'ADD NEW ROLE',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    )),
                  ),
                  buildTextFormField(nameController, 'Full Name'),
                  _buildImageRoleUpload(setModalState),
                  buildDropdown("Role", roles, selectedRole, (val) {
                    setModalState(
                        () => selectedRole = val); // 👈 Use setModalState
                  }),
                  buildDropdown("Department", departments, _selectedDepartment,
                      (val) {
                    setModalState(() =>
                        _selectedDepartment = val); // 👈 Use setModalState
                  }),
                  buildDropdown("Session", academicSessions, selectedSession,
                      (val) {
                    setModalState(
                        () => selectedSession = val); // 👈 Use setModalState
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        setModalState(
                            () => isLoading = true); // Start loading spinner
                        await _submitForm(
                            setModalState); // Pass setModalState to update UI
                        setModalState(
                            () => isLoading = false); // Stop loading spinner
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              5), // Add border radius here
                        ),
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 4,
                              ),
                            )
                          : Text("Submit",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Validation Function
  bool validateFields(BuildContext context, Map<String, dynamic> fields) {
    for (var entry in fields.entries) {
      if (entry.value == null || entry.value.toString().trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 Please fill in the '${entry.key}' field.",
              style: TextStyle(color: Colors.black),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.black),
            ),
            margin: EdgeInsets.all(16),
            elevation: 3,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          isLoading = false;
        });
        print("Please fill in the '${entry.key}' field.");
        return false; // Stop execution if any field is missing
      }
    }
    return true; // All fields are valid
  }

  Future<void> _submitForm(Function setModalState) async {
    setModalState(() => isLoading = true); // Show loading spinner

    Map<String, dynamic> formData = {};
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // 🔹 Fetch the user's role from Firestore
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();

    String userRole = userSnapshot['role'] ?? ''; // Default to empty if null

    // 🔹 Check if user is a "student" and restrict certain tabs
    if (userRole == 'student') {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🚫 Only class representatives or elected student posts can add excos!",
            style: TextStyle(color: Colors.black),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black),
          ),
          margin: EdgeInsets.all(16),
          elevation: 3,
          duration: Duration(seconds: 3),
        ),
      );
      _clearForm();
      setState(() {
        isLoading = false;
      });
      return; // Stop execution
    }

    // 🔹 File Upload Function
    Future<String?> uploadFile(File? file, String folder) async {
      if (file == null) return null;
      try {
        String fileName = "${userId}_${DateTime.now().millisecondsSinceEpoch}";
        Reference ref = FirebaseStorage.instance.ref("$folder/$fileName");
        UploadTask uploadTask = ref.putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        return await snapshot.ref.getDownloadURL();
      } catch (e) {
        print("❌ Error uploading file: $e");
        return null;
      }
    }

    String? imageUrl = await uploadFile(_imagePost, "excos");

    try {
      if (!validateFields(context, {
        "Full Name": nameController.text,
        "Image": imageUrl,
        "Role": selectedRole,
        "Session": selectedSession,
      })) {
        setModalState(() => isLoading = false);
        return;
      }

      CollectionReference excosRef =
          FirebaseFirestore.instance.collection('excos');

      String excosId = excosRef.doc().id;
      formData = {
        "userId": userId,
        "full_Name": nameController.text,
        "excosId": excosId,
        "image": imageUrl,
        "role": selectedRole,
        'department': _selectedDepartment,
        "session": selectedSession,
      };
      // 🔍 Query Firestore for potential conflicts
      QuerySnapshot existingExcos =
          await excosRef.where('session', isEqualTo: selectedSession).get();

      bool conflict = false;

      for (var doc in existingExcos.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final existingRole = data['role'];
        final existingDept = data['department'];

        // Case 1: Unique combo of role + department + session
        if (existingRole == selectedRole &&
            existingDept == _selectedDepartment) {
          conflict = true;
          break;
        }

        // Case 2: These roles must be globally unique for a session
        final uniqueRoles = [
          'Faculty President',
          'Faculty Vice President',
          'Sports Secretary'
        ];

        if (uniqueRoles.contains(selectedRole) &&
            existingRole == selectedRole) {
          conflict = true;
          break;
        }
      }

      if (conflict) {
        setModalState(() => isLoading = false);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 Conflict: This role is already assigned for the selected session.",
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.black),
            ),
            margin: EdgeInsets.all(16),
            elevation: 3,
          ),
        );
        return;
      }

      await excosRef.doc(excosId).set(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Data submitted successfully!.",
            style: TextStyle(color: Colors.black),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.black),
          ),
          margin: EdgeInsets.all(16),
          elevation: 3,
          duration: Duration(seconds: 3),
        ),
      );

      _clearForm();
      setModalState(() => isLoading = false);
      Navigator.pop(context); // Close modal
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => ExcosPage()));
    } catch (e) {
      print("❌ Error submitting data: $e");
      setModalState(() => isLoading = false);
    }
  }

  void fetchAllExcos() async {
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('excos').get();

      setState(() {
        profiles = snapshot.docs.map((doc) {
          return doc.data() as Map<String, dynamic>;
        }).toList();
      });
      print('THIS IS THE PROFILES: $profiles');
    } catch (e) {
      print("❌ Error fetching excos: $e");
      return;
    } finally {
      setState(() {
        isLoadingFetching = false;
      });
    }
  }

  Future<void> deleteExcos(String excosId) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Reference to the post document
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // 🔹 Fetch the user's role from Firestore
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      String userRole = userSnapshot['role'] ?? ''; // Default to empty if null

      // 🔹 Check if user is a "student" and restrict certain tabs
      if (userRole == 'student') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "🚫 Only class representatives or elected student posts can delete excos!",
              style: TextStyle(color: Colors.black),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.black),
            ),
            margin: EdgeInsets.all(16),
            elevation: 3,
            duration: Duration(seconds: 3),
          ),
        );
        _clearForm();
        setState(() {
          isLoading = false;
        });
        return; // Stop execution
      }

      DocumentReference excosRef =
          FirebaseFirestore.instance.collection('excos').doc(excosId);

      // Fetch the post data to get the image URL
      DocumentSnapshot excosSnapshot = await excosRef.get();
      if (!excosSnapshot.exists) {
        print("Post not found.");
        return;
      }

      Map<String, dynamic>? postData =
          excosSnapshot.data() as Map<String, dynamic>?;
      String? imageUrl = postData?['image'];

      // Delete the image from Firebase Storage if it exists
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          // Extract the file path from the URL
          String filePath = imageUrl
              .split('o/')[1] // Get the storage path
              .split('?')[0] // Remove query parameters
              .replaceAll('%2F', '/'); // Decode path

          await FirebaseStorage.instance.ref(filePath).delete();
          print("Image deleted successfully.");
        } catch (imageError) {
          print("Error deleting image: $imageError");
        }
      }

      // Delete the post itself
      await excosRef.delete();
      print("Post deleted successfully.");
    } catch (e) {
      print("Error deleting post: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => ExcosPage()));
      }
    }
  }

  void confirmDelete(excosId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Exco?",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black),
        ),
        content: Text("Are you sure you want to delete this exco?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () {
              deleteExcos(excosId);
              Navigator.pop(context);
            },
            child: isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text("Delete",
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void showDeleteBottomSheet(BuildContext context, excosId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows keyboard to push content up
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: Wrap(children: [
            Center(
              child: Container(
                width: 60,
                height: 5,
                margin: EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  confirmDelete(excosId);
                },
                child: Text("Delete Exco",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900)),
              ),
            ),
          ]),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          "Meet the Excos",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15),
        child: isLoadingFetching
            ? Center(
                child: CircularProgressIndicator(
                color: Colors.black,
              )) // Show loading indicator
            : profiles.isEmpty
                ? Center(child: Text("No excos available")) // Show empty state
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.50,
                    ),
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                          onLongPress: () => showDeleteBottomSheet(
                              context, profiles[index]['excosId']),
                          child: ProfileCard(profile: profiles[index]));
                    },
                  ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: FloatingActionButton(
          onPressed: () => showAddRoleBottomSheet(context),
          backgroundColor: Colors.black,
          elevation: 3.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5), // Add border radius here
          ),
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: const Icon(
              Icons.person_add_alt_rounded,
              color: Colors.white,
              size: 25.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem,
      ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: .0, top: 5),
            child: Text(label,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          SizedBox(height: 5),
          DropdownButtonFormField<String>(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
            value: selectedItem,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(5),
                borderSide: BorderSide(
                  color: Colors.black,
                  width: 1.5,
                ),
              ),
            ),
            isExpanded: false,
            // validator: (value) {
            //   if (value == null || value.isEmpty) {
            //     return "This field is required"; // Show validation message
            //   }
            //   return null;
            // },
            items: items
                .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                    )))
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget buildTextFormField(controller, titleHint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(
              color: Colors.black,
              width: 1.5,
            ),
          ),
          labelText: titleHint,
          labelStyle: TextStyle(color: Colors.black),
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildImageRoleUpload(Function setModalState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Upload Image",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _pickImagePost(setModalState), // Pass `setModalState`
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(5),
              color: Colors.grey[200],
            ),
            child: _imagePost != null
                ? Image.file(_imagePost!, fit: BoxFit.cover)
                : Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}

class Profile {
  final String name;
  final String image;
  final String role;

  Profile({required this.name, required this.image, required this.role});
}

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            // Match the Container's border radius
            child: SizedBox(
              width: double.infinity,
              height: 200,
              child: profile['image'] != null && profile['image'].isNotEmpty
                  ? Image.network(
                      profile['image'],
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
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 150, // Adjust based on your layout
              child: Text(
                textAlign: TextAlign.center,
                profile['full_Name'],
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13,
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
                textAlign: TextAlign.center,
                profile['role'],
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 11,
                ),
                softWrap: true,
              ),
            ),
            SizedBox(height: 5),
            SizedBox(
              width: 150,
              child: Text(
                textAlign: TextAlign.center,
                profile['department'] ?? 'Building',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 11,
                ),
                softWrap: true,
              ),
            ),
            SizedBox(height: 5),
            SizedBox(
              width: 150,
              child: Text(
                textAlign: TextAlign.center,
                profile['session'],
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 11,
                ),
                softWrap: true,
              ),
            ),
          ],
        )
      ],
    );
  }
}
