import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateContentScreen extends StatefulWidget {
  const CreateContentScreen({super.key});

  @override
  State<CreateContentScreen> createState() => _CreateContentScreenState();
}

class _CreateContentScreenState extends State<CreateContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Separate GlobalKey for each tab to prevent duplicate errors
  final List<GlobalKey<FormState>> _formKeys =
      List.generate(5, (index) => GlobalKey<FormState>());

  // Controllers for text inputs
  final List<TextEditingController> _titleControllers =
      List.generate(5, (index) => TextEditingController());

  File? _image;
  File? _document;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDocument() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _document = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitForm() {
    int activeTab = _tabController.index;
    if (_formKeys[activeTab].currentState!.validate()) {
      String title = _titleControllers[activeTab].text;

      Map<String, dynamic> formData = {
        "title": title,
        "image": _image?.path,
        "document": _document?.path,
        "date": _selectedDate?.toIso8601String(),
      };

      print("Submitted Data for Tab ${activeTab}:");
      print(formData);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Post submitted successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Faculty Content'),
        bottom: TabBar(
          controller: _tabController,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: Color(0xff347928),
              width: 3.0,
            ),
            insets: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.125),
          ),
          tabs: [
            Tab(icon: Icon(Icons.article), text: "Posts"),
            Tab(icon: Icon(Icons.event), text: "Events"),
            Tab(icon: Icon(Icons.book), text: "Resources"),
            Tab(icon: Icon(Icons.schedule), text: "Exam"),
            Tab(icon: Icon(Icons.schedule), text: "Lecture"),
          ],
          labelStyle: TextStyle(color: Color(0xff347928)),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(0, "Post Title", true, false, false),
          _buildForm(1, "Event Title", true, false, true),
          _buildForm(2, "Resource Title", false, true, false),
          _buildForm(3, "Exam Schedule Title", false, true, true),
          _buildForm(4, "Lecture Schedule Title", false, true, false),
        ],
      ),
    );
  }

  Widget _buildForm(int index, String titleHint, bool allowImage,
      bool allowDocument, bool allowDate) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[index], // Unique key for each tab
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleControllers[index],
              decoration: InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Color(0xff347928),
                    width: 1.5,
                  ),
                ),
                labelText: titleHint,
                labelStyle: TextStyle(color: Colors.black),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            if (allowImage) _buildImageUpload(),
            if (allowDocument) _buildDocumentUpload(),
            if (allowDate) _buildDatePicker(),
            Spacer(),
            ElevatedButton(
              onPressed: _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff347928),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text("Submit",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Image"),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
            ),
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Document"),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickDocument,
          icon: Icon(Icons.upload_file),
          label: Text("Choose File"),
        ),
        if (_document != null) Text("File selected: ${_document!.path}"),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select Date"),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickDate,
          icon: Icon(
            Icons.calendar_today,
            color: Colors.black,
          ),
          label: Text(
            _selectedDate == null
                ? "Pick a Date"
                : "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}",
            style: TextStyle(color: Colors.black),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
