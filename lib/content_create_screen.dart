import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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

  final TextEditingController ticketController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController courseCodeController = TextEditingController();

  File? _imagePost;
  File? _imageEvent;
  File? _imageLecture;
  File? _imageExam;
  File? _document;
  DateTime? _selectedDate;
  DateTime? _selectedDateEnd;
  String? selectedType;
  String? selectedDepartment;
  String? selectedLevel;
  String? selectedTags;
  String? selectedSemester;

  final List<String> departments = [
    "Architecture",
    "Building",
    "Urban & Regional Planning",
    "Estate Management",
    "Quantity Surveying"
  ];
  List<String> eventTags = [
    "Event",
    "HappeningSoon",
    "SaveTheDate",
    "JoinUs",
    "Networking",
    "Workshop",
    "Seminar",
    "Webinar",
    "Conference",
    "Meetup",
    "TechEvent",
    "Hackathon",
    "CareerFair",
    "StartupEvent",
    "Tech",
    "Business",
    "Finance",
    "Marketing",
    "Design",
    "Health",
    "Education",
    "Engineering",
    "RealEstate",
    "CampusEvent",
    "UniLife",
    "StudentMeetup",
    "CareerTalk",
    "ExamPrep",
    "AcademicEvent",
    "StudyGroup",
    "FreshersWeek",
    "LagosEvents",
    "UnilagEvent",
    "NigeriaTech",
    "LocalMeetup",
    "Concert",
    "Festival",
    "GameNight",
    "MovieNight",
    "Hangout",
    "AfterParty",
    "FunTimes",
    "SelfGrowth",
    "Inspiration",
    "SkillUp",
    "MindsetMatters",
    "LevelUp",
    "VirtualEvent",
    "LiveStream",
    "HybridConference",
    "OnlineWorkshop"
  ];

  final List<String> semester = ["First Semester", "Second Semester"];
  final List<String> levels = [
    "100 Level",
    "200 Level",
    "300 Level",
    "400 Level",
    "500 Level"
  ];
  final List<String> activeTabNames = [
    "Posts",
    "Events",
    "Resources",
    "Exam",
    "Lecture"
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  Future<void> _pickImagePost() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePost = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImageExam() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageExam = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImageLecture() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageLecture = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickImageEvent() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageEvent = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDocument() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
    );

    if (result != null) {
      File selectedFile = File(result.files.single.path!);
      setState(() {
        _document = selectedFile;
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

  Future<void> _pickDateEnd() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDateEnd = pickedDate;
      });
    }
  }

  void _submitForm() {
    int activeTab = _tabController.index;
    String currentTabName = activeTabNames[activeTab];
    if (_formKeys[activeTab].currentState!.validate()) {
      String title = _titleControllers[activeTab].text;
      Map<String, dynamic> formData = {};
      if (currentTabName == 'Posts') {
        formData = {
          "title": title,
          "currentPostTab": currentTabName,
          "image": _imagePost?.path,
          "date": _selectedDate?.toIso8601String(),
        };
      } else if (currentTabName == 'Events') {
        formData = {
          "title": title,
          "currentPostTab": currentTabName,
          "image": _imageEvent?.path,
          "date": _selectedDate?.toIso8601String(),
          "dateEnd": _selectedDateEnd?.toIso8601String(),
          "eventLocation": locationController.text,
          "eventTicketPrice": ticketController.text,
          "eventTag": selectedTags
        };
      } else if (currentTabName == 'Resources') {
        formData = {
          "title": title,
          "currentPostTab": currentTabName,
          "document": _document?.path,
          "department": selectedDepartment,
          "level": selectedLevel,
          "semester": selectedSemester,
          "courseCode": courseCodeController.text,
        };
      } else if (currentTabName == 'Exam') {
        formData = {
          "title": title,
          "currentPostTab": currentTabName,
          "image": _imageExam?.path,
          "date": _selectedDate?.toIso8601String(),
          "dateEnd": _selectedDateEnd?.toIso8601String(),
          "department": selectedDepartment,
          "level": selectedLevel,
          "semester": selectedSemester,
        };
      } else if (currentTabName == 'Lecture') {
        formData = {
          "title": title,
          "currentPostTab": currentTabName,
          "image": _imageLecture?.path,
          "department": selectedDepartment,
          "level": selectedLevel,
          "semester": selectedSemester,
        };
      }

      print("Submitted Data for Tab $activeTab: $activeTabNames");
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
          _buildForm(0, "Post Title", true, false, false, false, false, false,
              false, false, false, false),
          _buildForm(1, "Event Title", true, false, true, true, false, false,
              true, false, true, false),
          _buildForm(2, "Resource Title", false, true, false, false, true, true,
              false, true, false, true),
          _buildForm(3, "Exam Schedule Title", true, false, true, false, true,
              true, false, true, false, false),
          _buildForm(4, "Lecture Schedule Title", true, false, false, false,
              true, true, false, true, false, false),
        ],
      ),
    );
  }

  Widget _buildForm(
    int index,
    String titleHint,
    bool allowImage,
    bool allowDocument,
    bool allowDate,
    bool allowTicket,
    bool allowDepartment,
    bool allowLevel,
    bool allowTags,
    bool allowSemester,
    bool allowLocation,
    bool allowCourseCode,
  ) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKeys[index], // Unique key for each tab
        child: ListView(
          children: [
            buildTextFormField(_titleControllers[index],
                titleHint == 'Post Title' ? 'Caption' : titleHint),
            SizedBox(height: 10),
            if (allowImage && titleHint == 'Event Title')
              _buildImageEventUpload(),
            if (allowImage && titleHint == 'Post Title')
              _buildImagePostUpload(),
            if (allowImage && titleHint == 'Exam Schedule Title')
              _buildImageExamUpload(),
            if (allowImage && titleHint == 'Lecture Schedule Title')
              _buildImageLectureUpload(),
            if (allowDocument) _buildDocumentUpload(),
            if (allowDate) _buildDatePicker(),
            if (allowDate) _buildDatePickerEnd(),
            SizedBox(height: 5),
            if (allowTags)
              buildDropdown("Tags", eventTags, selectedTags, (val) {
                setState(() => selectedType = val);
              }),
            if (allowDepartment)
              buildDropdown("Department", departments, selectedDepartment,
                  (val) {
                setState(() => selectedType = val);
              }),
            if (allowDepartment) SizedBox(height: 5),
            if (allowLevel)
              buildDropdown("Level", levels, selectedLevel, (val) {
                setState(() => selectedType = val);
              }),
            if (allowLevel) SizedBox(height: 5),
            if (allowCourseCode)
              Text(
                'Course Code',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            if (allowCourseCode)
              SizedBox(
                height: 5,
              ),
            if (allowCourseCode)
              buildTextFormField(courseCodeController, 'e.g BLD 234'),
            SizedBox(height: 10),
            if (allowDocument) SizedBox(height: 5),
            if (allowSemester)
              buildDropdown("Semester", semester, selectedSemester, (val) {
                setState(() => selectedType = val);
              }),
            if (allowSemester) SizedBox(height: 5),
            if (allowTicket)
              Text(
                'Event Ticket Price',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            if (allowTicket)
              SizedBox(
                height: 5,
              ),
            if (allowTicket) buildTextFormField(ticketController, '30,000'),
            SizedBox(height: 10),
            if (allowLocation)
              Text(
                'Location',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            if (allowLocation)
              SizedBox(
                height: 5,
              ),
            if (allowLocation)
              buildTextFormField(locationController, 'Lagoon Front, Unilag'),
            if (allowLocation) SizedBox(height: 10),
            // buildDropdown("Document Type", documentTypes, selectedType, (val) {
            //   setState(() => selectedType = val);
            // }),
            SizedBox(
              height: 10,
            ),
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

  Widget buildTextFormField(controller, titleHint) {
    return TextFormField(
      controller: controller,
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
            child: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
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
                  color: Color(0xff347928),
                  width: 1.5,
                ),
              ),
            ),
            isExpanded: false,
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

  Widget _buildImagePostUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Image"),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImagePost,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
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

  Widget _buildImageLectureUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Image"),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImagePost,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
            ),
            child: _imageLecture != null
                ? Image.file(_imageLecture!, fit: BoxFit.cover)
                : Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageExamUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Image"),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImagePost,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
            ),
            child: _imageExam != null
                ? Image.file(_imageExam!, fit: BoxFit.cover)
                : Icon(Icons.camera_alt, size: 50, color: Colors.grey),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildImageEventUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Upload Image"),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImageEvent,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey[200],
            ),
            child: _imageEvent != null
                ? Image.file(_imageEvent!, fit: BoxFit.cover)
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
          icon: Icon(
            Icons.upload_file,
            color: Colors.black,
          ),
          label: Text(
            "Choose File",
            style: TextStyle(color: Colors.black),
          ),
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
        Text("Select Start Date"),
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

  Widget _buildDatePickerEnd() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Select End Date"),
        SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _pickDateEnd,
          icon: Icon(
            Icons.calendar_today,
            color: Colors.black,
          ),
          label: Text(
            _selectedDateEnd == null
                ? "Pick a Date"
                : "${_selectedDateEnd!.day}-${_selectedDateEnd!.month}-${_selectedDateEnd!.year}",
            style: TextStyle(color: Colors.black),
          ),
        ),
        SizedBox(height: 16),
      ],
    );
  }
}
